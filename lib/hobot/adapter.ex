defmodule Hobot.Adapter do
  @name_suffix "Adapter"

  def build_name(atom) do
    Module.concat(atom, @name_suffix)
  end
end
