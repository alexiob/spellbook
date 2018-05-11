defmodule Spellbook.Parser.YAML do
  @moduledoc """
  YAML data parser.
  """
  @behaviour Spellbook.Parser

  def parse(data) do
    try do
      data = YamlElixir.read_from_string!(data)
      {:ok, data}
    catch
      _, {_, [reason | _]} ->
        {_, :error, reason, _, _, _, _, _} = reason
        {:error, reason}
    end
  end
end
