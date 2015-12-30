defmodule Thalamex.Thing.Backend do
  def publish(name, message) do
    Application.get_env(:thalamex, :cortex)
    |> :rpc.call(Cortex.Thing, :push_message, [name, message])
  end

  def get_code_for(name) do
    Application.get_env(:thalamex, :cortex)
    |> :rpc.call(Cortex.Thing, :get_code_for, [name])
  end

  def get_code_for(name, fun) do
    case get_code_for(name) do
      {:ok, code} -> fun.(code)
      _ -> nil
    end
  end

  def module_name(name) do
    get_code_for(name, fn(code) ->
      Thalamex.Thing.Code.module_name(name)
      |> String.to_atom()
    end)
  end

  def build_module(name) do
    get_code_for(name, fn(code) ->
      Thalamex.Thing.Code.to_module(code, name)
    end)
  end
end
