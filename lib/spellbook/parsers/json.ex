defmodule Spellbook.Parser.JSON do
  @moduledoc """
  JSON data parser.
  """
  @behaviour Spellbook.Parser

  def parse(data) do
    case Poison.decode(data) do
      {:ok, data} ->
        {:ok, data}

      {:error, reason} ->
        reason = "#{to_string(elem(reason, 0))} '#{elem(reason, 1)}'"
        {:error, reason}
    end
  end
end
