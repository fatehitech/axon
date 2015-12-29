defmodule Thalamex.Worker do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, manager} = Thalamex.Thing.Manager.start_link
    spawn_link(fn ->
      Thalamex.Thing.Manager.loop(manager)
    end)
    {:ok, {manager}}
  end
end
