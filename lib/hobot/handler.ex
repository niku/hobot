defmodule Hobot.Handler do
  @name_suffix "Handler"

  def build_name(atom, index) do
    Module.concat(atom, @name_suffix)
    |> Module.concat(Integer.to_string(index))
  end
end
