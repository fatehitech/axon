defmodule Thalamex.Worker do
  use GenServer
  alias Thalamex.Thing.Supervisor, as: Coordinator
  alias Thalamex.Thing.Backend, as: Backend

  @cortex Application.get_env(:thalamex, :cortex)
  @standalone Application.get_env(:thalamex, :standalone, false)
  @standalone_name Application.get_env(:thalamex, :standalone_name)

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, manager} = Thalamex.Thing.Manager.start_link

    if @standalone do
      send(self, :start_standalone)
    else
      spawn_link(fn ->
        Thalamex.Thing.Manager.loop(manager)
      end)
    end

    :timer.send_interval(5_000, :connect)
    send(self, :connect)
    {:ok, {manager}}
  end

  def handle_info(:connect, state) do
    @cortex
    |> Node.connect
    {:noreply, state}
  end

  def handle_info(:start_standalone, state) do
    pid = :erlang.whereis(Coordinator)
    if Coordinator.empty?(pid) do
      mod = Backend.build_module(@standalone_name)
      if mod do
        Coordinator.start_standalone(pid, mod)
      else
        :timer.send_after(5_000, :start_standalone)
      end
    end
    {:noreply, state}
  end
end
