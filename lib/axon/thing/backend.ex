defmodule Axon.Thing.Backend do
  def publish(name, message) do
    out = Application.get_env(:axon, :cortex)
    |> :rpc.call(Cortex.Thing, :handle_in, [name, message])
    IO.inspect out
    out
  end

  def get_code_for(name) do
    out = Application.get_env(:axon, :cortex)
    |> :rpc.call(Cortex.Thing, :get_code_for, [name])
    IO.inspect out
    out
  end

  def get_code_for(name, fun) do
    case get_code_for(name) do
      {:ok, code} -> fun.(code)
      _ -> nil
    end
  end

  def module_name(name) do
    get_code_for(name, fn(code) ->
      Axon.Thing.Code.module_name(name)
      |> String.to_atom()
    end)
  end

  def build_module(name) do
    get_code_for(name, fn(code) ->
      Axon.Thing.Code.to_module(code, name)
    end)
  end
end
