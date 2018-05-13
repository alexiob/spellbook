defmodule SpellbookParserYAMLTest do
  use ExUnit.Case
  doctest Spellbook.Parser.YAML, except: [:moduledoc]

  test "parse valid YAML" do
    test = """
    test: 1
    """

    {:ok, config} = Spellbook.Parser.YAML.parse(test)

    assert Map.get(config, "test") == 1
  end

  test "parse invalid YAML" do
    test = """
    test: 1
    , error
    """

    {:error, _} = Spellbook.Parser.YAML.parse(test)
  end
end
