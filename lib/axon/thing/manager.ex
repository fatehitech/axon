defmodule Axon.Thing.Manager do
  @moduledoc """
  A loop identifies each **unknown** and **unconnected** operating system
  tty that looks like a serial port by probing it (connecting to it)
  in order to launch stored Firmata code under a supervisor.
  * If no probes are active, waits 5 seconds before looping again
  * If probes are active, waits 10 seconds, then closes any open probe
  * On receive `firmware_name`, closes the probe and saves the name
  * For each tty identification, lookup matching `firmware_name` in database
  * If code is found in the database for this `firmware_name`, start it supervised
  * Detects **known** devices which have been lost/unplugged and stops them via supervisor

  Standalone mode disables all the serial port stuff.
  It's useful for orchestrating a device that has no attached arduinos.
  """

  @disconnected 0
  @connected 1
  @known 2

  use GenServer

  alias Axon.Thing.Probe, as: Probe
  alias Axon.Thing.Supervisor, as: Coordinator
  alias Axon.TtyList, as: SerialPorts
  alias Axon.Thing.Backend, as: Backend

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    ttys = []
    scan_pids = []
    {:ok, sup} = Coordinator.start_link(name: Coordinator)
    {:ok, {ttys, scan_pids, sup}}
  end

  def loop(manager) do
    count = GenServer.call(manager, :tick)
    if count == 0 do
      :timer.sleep 5_000
    else
      :timer.sleep 10_000
    end
    send(manager, :tock)
    loop(manager)
  end

  @doc """
  Used by Cortex to push messages to connected things
  The name param is that stored in the Cortex db
  The message can be a tuple or whatever you want
  to handle in the handle_info function

  Example of calling this from Cortex
  Node.list()
  |> List.first()
  |> :rpc.call(Axon.Thing.Manager, :send_thing, ["Metro.ino", :blink])
  """
  def send_thing(name, message) do
    mod_name = name
    |> Axon.Thing.Code.module_name()
    |> String.to_atom
    :erlang.whereis(Coordinator)
    |> Coordinator.send_device(mod_name, message)
  end

  @doc """
  Like send_thing but uses GenServer.call in order to get a response
  """
  def call_thing(name, message) do
    mod_name = name
    |> Axon.Thing.Code.module_name()
    |> String.to_atom
    :erlang.whereis(Coordinator)
    |> Coordinator.call_device(mod_name, message)
  end

  @doc """
  Stops and restarts the child process.
  """
  def reset_thing(name) do
    IO.puts "resetting thing #{name}"
    mod_name = name
    |> Axon.Thing.Code.module_name()
    |> String.to_atom

    # Recompile
    Backend.build_module(name)

    :erlang.whereis(Coordinator)
    |> Coordinator.restart_device(mod_name)
  end

  @doc """
  Causes identification on each unknown and unconnected tty
  """
  def handle_call(:tick, _from, {tty_list, pids,sup}) do
    new_tty_list = SerialPorts.get
    |> update_tty_list(tty_list)
    |> identify

    lost_knowns(tty_list, new_tty_list)
    |> Enum.each(fn({path, name, _})->
      send(self(), {:lost, path, name})
    end)

    connected_count = Enum.count(new_tty_list, fn({_,_,state})-> state == @connected end)

    {:reply, connected_count, {new_tty_list, pids, sup}}
  end

  @doc """
  Closes any connected tty running the Firmata identifier
  """
  def handle_info(:tock, {ttys, ident_pids, sup}) do
    ttys = remove_connected(ttys)
    Enum.each(ident_pids, &Probe.stop(elem(&1, 1)))
    {:noreply, {ttys, [], sup}}
  end

  @doc """
  Probe a tty for Firmata by connecting to it. Good boards (Uno, Metro)
  wire RS232 DTR to a board reset, and Firmata tells us its firmware
  name on startup. That's why this works.
  """
  def handle_info({:probe, tty_path}, {tty_list, ident_pids, sup}) do
    {:ok, pid} = Probe.start_link(tty_path, 57600, self())
    {:noreply, {tty_list, [{tty_path, pid}|ident_pids], sup}}
  end

  @doc """
  Stop probing the tty by disconnecting the serial port

  If we have code for this thing, start it up in the supervisor
  """
  def handle_info({:unprobe, tty_path, name}, {tty_list, ident_pids, sup}) do
    ident_pids = disconnect(ident_pids, tty_path, fn(pid) ->
      Probe.stop(pid)
      module = Backend.build_module(name)
      if module do
        Coordinator.start_device(sup, tty_path, module)
      end
    end)
    {:noreply, {tty_list, ident_pids, sup}}
  end

  @doc """
  Received when we have identified a tty to be running Firmata
  """
  def handle_info({:identified, tty_path, name}, {tty_list, ident_pids, sup}) do
    {:noreply, {identified(tty_list, tty_path, name), ident_pids, sup}}
  end

  @doc """
  Received when we have lost a known Firmata device
  Stopping any process you started when it was identified
  """
  def handle_info({:lost, _, name}, {_,_,sup}=state) do
    module_name = Backend.module_name(name)
    if module_name do
      Coordinator.stop_device(sup, module_name)
    end
    {:noreply, state}
  end

  @doc """
  Takes list of tty tuples and returns a new list with any
  that were in the connected state having been removed
  """
  def remove_connected(ttys) do
    Enum.reduce(ttys, [], fn({_, _, status} = tty, result) ->
      if status == @connected do
        result
      else
        [tty|result]
      end
    end)
    |> Enum.reverse
  end

  @doc """
  takes a list of pid tuples, finds the one with the tty name,
  removes it from the list, calls the callback with it,
  and then returns the list
  """
  def disconnect(ident_pids, tty_path, found_callback) do
    Enum.reduce(ident_pids, [], fn({path, pid} = item, result) ->
      if path == tty_path do
        found_callback.(pid)
        result
      else
        [item|result]
      end
    end)
    |> Enum.reverse()
  end

  @doc """
  Takes a list of tty tuples and updates the one
  with the given path with the given name and status 2
  triggering a disconnect event for it and returning the list
  """
  def identified(ttys, tty_path, firmware_name) do
    Enum.reduce(ttys, [], fn({path, _, status} = tty, result) ->
      if status == @connected and path == tty_path do
        send(self, {:unprobe, path, firmware_name})
        [{path, firmware_name, @known}|result]
      else
        [tty|result]
      end
    end)
    |> Enum.reverse
  end


  @doc """
  Takes a list of tuples and examines the status
  of each one. If 0 we trigger a scan
  and set the status to 1 so we dont trigger again
  returns the list
  """
  def identify(ttys) do
    Enum.reduce(ttys, [], fn({path, name, status} = tty, result) ->
      if status == @disconnected do
        send(self, {:probe, path})
        [{path, name, @connected}|result]
      else
        [tty|result]
      end
    end)
    |> Enum.reverse
  end

  @doc """
  Takes the system tty and current list of seen ttys
  and produces new list of seen ttys by removing or adding
  while converting to desired tuple structure
  """
  def update_tty_list(sys_ttys, seen_ttys) do
    Enum.reduce(sys_ttys, [], fn(sys_tty, result)->
      seen = Enum.find(seen_ttys, &(elem(&1, 0) == sys_tty))
      if seen do
        [seen|result]
      else
        [{sys_tty, nil, 0}|result]
      end
    end)
    |> Enum.reverse
  end

  @doc """
  Reveals which ttys that were otherwise known, are now lost
  """
  def lost_knowns(prev_ttys, new_ttys) do
    Enum.reject(prev_ttys, fn({_, _, status})->
      status != @known
    end)
    |> Enum.reduce([], fn({prev_path, _, _} = prev_tty, result) ->
      located = Enum.find(new_ttys, false, fn({other_path, _, _}) ->
        prev_path == other_path
      end)
      if located == false do
        [prev_tty|result]
      else
        result
      end
    end)
  end
end
