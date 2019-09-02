defmodule Spellbook.Parser.YAML do
  @moduledoc """
  YAML data parser.
  """
  @behaviour Spellbook.Parser

  def parse(data) do
    YamlElixir.read_from_string(data)
  end
end
