defmodule SpellbookParserYAMLTest do
  use ExUnit.Case
  alias Spellbook.Parser.YAML

  doctest Spellbook.Parser.YAML, except: [:moduledoc]

  test "parse valid YAML" do
    test = """
    test: 1
    """

    {:ok, config} = YAML.parse(test)

    assert Map.get(config, "test") == 1
  end

  test "parse invalid YAML" do
    test = """
    test: 1
    , error
    """

    {:error, _} = YAML.parse(test)
  end
end
