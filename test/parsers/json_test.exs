defmodule SpellbookParserJSONTest do
  use ExUnit.Case
  alias Spellbook.Parser.JSON
  doctest Spellbook.Parser.JSON, except: [:moduledoc]

  test "parse valid JSON" do
    {:ok, config} = JSON.parse(~S'{"test":1}')

    assert Map.get(config, "test") == 1
  end

  test "parse invalid JSON" do
    {:error, _} = JSON.parse("{'test':1}")
  end
end
