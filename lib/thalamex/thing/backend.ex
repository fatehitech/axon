defmodule Thalamex.Thing.Backend do
  def get_code_for(name) do
    :rpc.call(:"cortex@synapse", Cortex.Thing, :get_code_for, ["Uno.ino"])
  end

  def module_name(name) do
    code = get_code_for(name)
    if code do
      Thalamex.Thing.Code.module_name(name)
      |> String.to_existing_atom()
    else
      nil
    end
  end

  def build_module(name) do
    code = get_code_for(name)
    if code do
      Thalamex.Thing.Code.to_module(code, name)
    else
      nil
    end
  end
end
