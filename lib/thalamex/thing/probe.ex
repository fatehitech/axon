defmodule Thalamex.Thing.Probe do
  use GenServer
  require Serial
  use Firmata.Protocol.Modes
  alias Firmata.Board, as: Board

  def start_link(tty, baudrate, owner, opts \\ []) do
    GenServer.start_link(__MODULE__, [tty, baudrate, owner], opts)
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def init([tty, baudrate, owner]) do
    {:ok, serial} = Serial.start_link
    {:ok, board} = Board.start_link
    Serial.open(serial, tty)
    Serial.set_speed(serial, baudrate)
    Serial.connect(serial)
    {:ok, {board, serial, tty, owner}}
  end

  def handle_call(:stop, _from, state) do
    state |> elem(0) |> GenServer.call(:stop)
    state |> elem(1) |> Serial.stop()
    {:stop, :normal, :ok, state}
  end

  def handle_info({:firmata, {:version, _major, _minor}}, state) do
    {:noreply, state}
  end

  def handle_info({:firmata, {:firmware_name, name}}, {_board, _serial, tty, owner} = state) do
    send(owner, {:identified, tty, name})
    {:noreply, state}
  end

  def handle_info({:firmata, {:pin_map, _pin_map}}, state) do
    {:noreply, state}
  end

  def handle_info({:elixir_serial, _serial, data}, {board, _, _, _} = state) do
    send(board, {:serial, data})
    {:noreply, state}
  end

  def handle_info({:firmata, {:send_data, data}}, {_, serial, _, _} = state) do
    Serial.send_data(serial, data)
    {:noreply, state}
  end
end
