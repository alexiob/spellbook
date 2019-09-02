defmodule Spellbook.Parser.JSON do
  @moduledoc """
  JSON data parser.
  """
  @behaviour Spellbook.Parser

  def parse(data) do
    Jason.decode(data)
  end
end
