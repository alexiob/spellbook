defmodule SpellbookParserJSONTest do
  use ExUnit.Case
  doctest Spellbook.Parser.JSON, except: [:moduledoc]

  test "parse valid JSON" do
    {:ok, config} = Spellbook.Parser.JSON.parse(~S'{"test":1}')

    assert Map.get(config, "test") == 1
  end

  test "parse invalid JSON" do
    {:error, _} = Spellbook.Parser.JSON.parse("{'test':1}")
  end
end
