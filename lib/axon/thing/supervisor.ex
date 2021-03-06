defmodule Axon.Thing.Supervisor do
  use Supervisor
  alias Axon.Thing.Backend, as: Backend

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    children = []
    supervise(children, strategy: :one_for_one)
  end

  def empty?(pid) do
    count = pid
    |> Supervisor.which_children()
    |> length
    count === 0
  end

  def start_device(pid, tty_path, module) do
    Supervisor.start_child(pid, worker(module, [tty_path, 57600]))
  end

  def start_standalone(pid, module) do
    Supervisor.start_child(pid, worker(module, []))
  end

  def stop_device(pid, child_id) do
    :ok = Supervisor.terminate_child(pid, child_id)
    :ok = Supervisor.delete_child(pid, child_id)
  end

  def restart_device(pid, child_id) do
    :ok = Supervisor.terminate_child(pid, child_id)
    :ok = Supervisor.restart_child(pid, child_id)
  end

  def send_device(pid, child_id, message) do
    pid
    |> Supervisor.which_children()
    |> Enum.find(fn(child)-> elem(child, 0) == child_id end)
    |> elem(1)
    |> send(message)
  end

  def call_device(pid, child_id, message) do
    pid
    |> Supervisor.which_children()
    |> Enum.find(fn(child)-> elem(child, 0) == child_id end)
    |> elem(1)
    |> GenServer.call(message)
  end
end
