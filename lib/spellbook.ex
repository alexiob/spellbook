defmodule Spellbook do
  @default_config_name "config"

  defstruct [
    filename_formats: [],
    extensions: ["json", "yaml"],
    vars: %{
      env: nil,
    },
    options: %{
      ignore_invalid_filename_formats: true,
    }
  ]

  require Logger

  # UTILITIES

  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end
  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end
  defp deep_resolve(_key, _left, right) do
    right
  end

  defp get_hostnames() do
    {:ok, full_hostname} = :inet.gethostname()
    full_hostname = to_string(full_hostname)
    short_hostname = to_string(String.split(full_hostname, ".", parts: 1))

    short_hostname = case short_hostname do
      ^full_hostname -> nil
    end

    {full_hostname, short_hostname}
  end

  defp set_config_name(params) when is_map(params) do
    vars = params[:vars] || []

    vars = case Map.has_key?(params, :config_filename) do
      true -> [{:config_filename, Map.get(params, :config_filename)}] ++ vars
      false -> vars
    end

    vars = case Keyword.has_key?(vars, :config_filename) do
      false -> [{:config_filename, @default_config_name}] ++ vars
      true -> vars
    end

    Map.put(params, :vars, vars)
  end

  def config_get(config=%{}, key) do
    DotNotes.get(config, key)
  end

  # FILE FORMATS
  defmacro add_filename_format(spellbook, filename_formats) when is_list(filename_formats) do
    filename_formats = Macro.escape(filename_formats)

    quote do
      current_filename_formats = Map.get(unquote(spellbook), :filename_formats, [])
      Map.put(unquote(spellbook), :filename_formats, current_filename_formats ++ unquote(filename_formats))
    end
  end

  defmacro add_filename_format(spellbook, filename_format) do
    filename_format = Macro.escape(filename_format)

    quote do
      current_filename_formats = Map.get(unquote(spellbook), :filename_formats, [])
      Map.put(unquote(spellbook), :filename_formats, current_filename_formats ++ [unquote(filename_format)])
    end
  end

  # FILE LIST GENERATOR
  def generate(spellbook) do
    generate(spellbook, config_filename: @default_config_name)
  end
  def generate(spellbook, nil) do
    generate(spellbook)
  end
  def generate(spellbook=%Spellbook{}, params=%{}) do
    params = Map.merge(%{config_filename: @default_config_name, vars: %{}}, params)
    |> set_config_name()

    merged_vars = Map.merge(Map.get(spellbook, :vars), Map.new(Map.get(params, :vars, %{})))
    |> Map.to_list()
    |> Enum.filter(fn(v) -> !is_nil(elem(v, 1)) end)

    Enum.flat_map(spellbook.filename_formats,
      fn(f) ->
        Enum.map(spellbook.extensions,
          fn(e) ->
            merged_vars = Keyword.put(merged_vars, :ext, e)

            try do
              {text, _} = Code.eval_quoted(f, merged_vars)
              text
            rescue
              e in CompileError ->
                case spellbook.options.ignore_invalid_filename_formats do
                  false -> throw e
                  true ->
                    # Logger.debug("Skipping filename format: #{e.description}")
                    nil
                end
            end
          end
        )
      end
    )
    |> Enum.filter(&(!is_nil(&1)))
  end

  # VARIABLES
  def set_vars(spellbook=%Spellbook{}, values) when is_nil(values) do
    spellbook
  end
  def set_vars(spellbook=%Spellbook{}, values) when is_list(values) do
    Enum.reduce(values, spellbook, fn(value, spellbook) -> set_var(spellbook, value) end)
  end
  def set_var(spellbook=%Spellbook{}, {name, value}) do
    set_var(spellbook, name, value)
  end
  def set_var(spellbook=%Spellbook{}, name, value) do
    Map.put(spellbook, :vars, Map.put(Map.get(spellbook, :vars), name, value))
  end

  # OPTIONS
  def set_options(spellbook=%Spellbook{}, options) when is_nil(options) do
    spellbook
  end
  def set_options(spellbook=%Spellbook{}, options) when is_list(options) do
    set_options(spellbook, Map.new(options))
  end
  def set_options(spellbook=%Spellbook{}, options) when is_map(options) do
    Map.put(spellbook, :options, Map.merge(Map.get(spellbook, :options), options))
  end

  # DEFAULT CONFIG FOLDER
  def default_config_folder(params) when is_list(params) do
    default_config_folder(%Spellbook{}, Map.new(params))
  end
  def default_config_folder(params) when is_map(params) do
    default_config_folder(%Spellbook{}, params)
  end
  def default_config_folder(spellbook=%Spellbook{} \\ %Spellbook{}, params \\ %{}) do
    {full_hostname, short_hostname} = get_hostnames()

    params = set_config_name(params)

    spellbook
    |> add_filename_format([
      "default.#{ext}",
      "default-#{instance}.#{ext}",

      "#{env}.#{ext}",
      "#{env}-#{instance}.#{ext}",

      "#{short_hostname}.#{ext}",
      "#{short_hostname}-#{instance}.#{ext}",
      "#{short_hostname}-#{env}.#{ext}",
      "#{short_hostname}-#{env}-#{instance}.#{ext}",

      "#{full_hostname}.#{ext}",
      "#{full_hostname}-#{instance}.#{ext}",
      "#{full_hostname}-#{env}.#{ext}",
      "#{full_hostname}-#{env}-#{instance}.#{ext}",

      "local.#{ext}",
      "local-#{instance}.#{ext}",
      "local-#{env}.#{ext}",
      "local-#{env}-#{instance}.#{ext}",
    ])
    |> set_vars([full_hostname: full_hostname, short_hostname: short_hostname])
    |> set_vars(params[:vars])
    |> set_options(params[:options])
  end

  # DEFAULT CONFIG
  def default_config(params) when is_list(params) do
    default_config(%Spellbook{}, Map.new(params))
  end
  def default_config(params) when is_map(params) do
    default_config(%Spellbook{}, params)
  end
  def default_config(spellbook=%Spellbook{} \\ %Spellbook{}, params \\ %{}) do
    {full_hostname, short_hostname} = get_hostnames()

    params = set_config_name(params)

    spellbook
    |> add_filename_format([
      "#{config_filename}.#{ext}",
      "#{config_filename}-#{instance}.#{ext}",
      "#{config_filename}-#{env}.#{ext}",
      "#{config_filename}-#{full_hostname}-#{env}-#{instance}.#{ext}"
    ])
    |> set_vars([full_hostname: full_hostname, short_hostname: short_hostname])
    |> set_vars(params[:vars])
    |> set_options(params[:options])
  end

  # CONFIGURATION LOADING
  def load_config_folder(params) do
    default_config_folder(params)
    |> load_config(params)
  end
  def load_config_folder(spellbook=%Spellbook{}, params=%{}) do
    spellbook
    |> set_vars(params[:vars])
    |> set_options(params[:options])
    |> load_config(params)
  end

  def load_config(params) when is_list(params) do
    Spellbook.default_config()
    |> Spellbook.load_config(params)
  end
  def load_config(spellbook=%Spellbook{}, params) when is_list(params) do
    load_config(spellbook, Map.new(params))
  end
  def load_config(spellbook=%Spellbook{}, params=%{}) do
    config_files = generate(spellbook, params)
    config_folder = Map.get(params, :folder, __DIR__)

    {_, config} = Enum.map_reduce(config_files, %{}, &(load_and_merge_config_file(Path.join(config_folder, &1), &2)))

    config = case Map.get(params, :config) do
      data when is_map(data) -> deep_merge(config, data)
      data when is_list(data) -> deep_merge(config, Map.new(data))
      nil -> config
    end

    #TODO: merge ENV vars from <FOLDER>/<CONFIG_FILENAME>-env-variables.<EXT>
    #TODO: merge CLI parameters from <FOLDER>/<CONFIG_FILENAME>-cli-variables.<EXT>

    config
  end

  def load_and_merge_config_file(filename, config=%{}) do
    result = case File.read(filename) do
      {:ok, data} ->
        case Path.extname(filename) do
          ".json" ->
            case Poison.decode(data) do
              {:ok, data} -> {:ok, data}
              {:error, reason} ->
                reason = "#{to_string(elem(reason, 0))} '#{elem(reason, 1)}'"
                Logger.debug("Error decoding '#{filename}': #{reason}")
                {:error, reason}
            end
          ".yaml" ->
            try do
              data = YamlElixir.read_from_string(data)
              {:ok, data}
            catch
              _, {_, [reason | _]} ->
                {_, :error, reason, _, _, _, _, _} = reason
                Logger.debug("Error decoding '#{filename}': #{reason}")
                {:error, reason}
            end
        end
      {:error, reason} ->
        case reason do
          :enoent -> nil
          true -> Logger.debug("Error loading '#{filename}': #{reason}")
        end
        {:error, reason}
    end

    case result do
      {:ok, data} -> {filename, deep_merge(config, data)}
      {:error, _} -> {filename, config}
    end
  end
end
