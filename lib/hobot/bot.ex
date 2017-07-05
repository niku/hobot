defmodule Hobot.Bot do
  @name_prefix __MODULE__

  def build_name(name) do
    Module.concat(@name_prefix, name)
  end

  def bot(atom), do: build_name(atom)
  def pub_sub(atom), do: Hobot.PubSub.build_name(bot(atom))
  def adapter(atom), do: Hobot.Adapter.build_name(bot(atom))

  def make_context(name) do
    %{
      bot: bot(name),
      pub_sub: pub_sub(name),
      adapter: adapter(name),
      subscribe: fn(topic) ->
        Hobot.PubSub.subscribe(pub_sub(name), topic)
      end,
      publish: fn (topic, from, ref, data) ->
        Hobot.PubSub.publish(pub_sub(name), topic, from, ref, data)
      end,
      unsubscribe: fn(topic) ->
        Hobot.PubSub.unsubscribe(pub_sub(name), topic)
      end
    }
  end
end
