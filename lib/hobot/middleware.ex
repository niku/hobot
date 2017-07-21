defmodule Hobot.Middleware do
  @default %{
    before_publish: [],
    before_receive: []
  }

  def build(conf) do
    Map.get(conf, :middleware, @default)
    |> Map.take(Map.keys(@default))
  end

  def apply_middleware(middlewares, value) do
    do_apply_middleware(middlewares, {:ok, value})
  end

  defp do_apply_middleware(_, {:halt, value}), do: {:halt, value}
  defp do_apply_middleware([], {:ok, value}), do: {:ok, value}
  defp do_apply_middleware([h|t], {:ok, value}) when is_function(h), do: do_apply_middleware(t, apply(h, [value]))
  defp do_apply_middleware([{m,f}|t], {:ok, value}) when is_atom(m) and is_atom(f), do: do_apply_middleware(t, apply(m, f, [value]))
end
