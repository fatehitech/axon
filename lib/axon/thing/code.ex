defmodule Axon.Thing.Code do
  def module_name(name) do
    basename =
      name
      |> String.replace(".ino", "")
      |> String.capitalize()
    ~s(Elixir.Thing.#{basename})
  end

  def to_module(body, name) do
    body
    |> Code.compile_string()
    |> List.first()
    |> elem(0)
  end
end
