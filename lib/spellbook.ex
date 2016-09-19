defmodule Spellbook do
  @default_config_filename "config"
  @default_env_filename "custom-env-variables"

  defstruct [
    filename_formats: [],
    extensions: %{},
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

  def substitute_vars(config = %{}, vars = %{}) do
    Map.merge(config, config, fn (key, config, _config) -> substitute_vars_resolve(key, config, vars) end)
  end
  defp substitute_vars_resolve(_key, config = %{}, vars) do
    substitute_vars(config, vars)
  end
  defp substitute_vars_resolve(_key, config, vars) do
    Map.get(vars, config, config)
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
    vars = Map.get(params, :vars, Keyword.new())
    vars = case Map.has_key?(params, :config_filename) do
      true -> Keyword.put_new(vars, :config_filename, Map.get(params, :config_filename))
      false -> vars
    end

    vars = case Keyword.has_key?(vars, :config_filename) do
      false -> [{:config_filename, @default_config_filename}] ++ vars
      true -> vars
    end

    Map.put(params, :vars, vars)
  end

  def config_get(config = %{}, key) do
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
    generate(spellbook, config_filename: @default_config_filename)
  end
  def generate(spellbook, nil) do
    generate(spellbook)
  end
  def generate(spellbook = %Spellbook{}, params = %{}) do
    params = Map.merge(%{config_filename: @default_config_filename, vars: Keyword.new()}, params)
    |> set_config_name()

    merged_vars = Map.merge(Map.get(spellbook, :vars), Map.new(Map.get(params, :vars, Keyword.new())))
    |> Map.to_list()
    |> Enum.filter(fn(v) -> !is_nil(elem(v, 1)) end)

    config_files = Enum.flat_map(spellbook.filename_formats,
      fn(f) ->
        Enum.map(spellbook.extensions,
          fn({e, _}) ->
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

    {config_files, params}
  end

  # VARIABLES
  def set_vars(spellbook = %Spellbook{}, values) when is_nil(values) do
    spellbook
  end
  def set_vars(spellbook = %Spellbook{}, values) when is_list(values) do
    Enum.reduce(values, spellbook, fn(value, spellbook) -> set_var(spellbook, value) end)
  end
  def set_var(spellbook = %Spellbook{}, {name, value}) do
    set_var(spellbook, name, value)
  end
  def set_var(spellbook = %Spellbook{}, name, value) do
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

  # EXTENSIONS
  def register_default_extensions(spellbook = %Spellbook{}) do
    default_extensions = %{
      "json" => Spellbook.Parser.JSON,
      "yaml" => Spellbook.Parser.YAML,
    }
    register_extensions(spellbook, default_extensions)
  end
  def register_extensions(spellbook = %Spellbook{}, extensions = %{}) do
    Map.put(spellbook, :extensions, Map.merge(spellbook.extensions, extensions))
  end

  # DEFAULT CONFIG FOLDER
  def default_config_folder(params) when is_list(params) do
    default_config_folder(%Spellbook{}, Map.new(params))
  end
  def default_config_folder(params) when is_map(params) do
    default_config_folder(%Spellbook{}, params)
  end
  def default_config_folder(spellbook = %Spellbook{} \\ %Spellbook{}, params \\ %{}) do
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
    |> register_default_extensions
  end

  # DEFAULT CONFIG
  def default_config(params) when is_list(params) do
    default_config(%Spellbook{}, Map.new(params))
  end
  # def default_config(params) when is_map(params) do
  #   default_config(%Spellbook{}, params)
  # end
  def default_config(spellbook = %Spellbook{} \\ %Spellbook{}, params \\ %{}) do
    {full_hostname, short_hostname} = get_hostnames()

    params = set_config_name(params)

    spellbook
    |> add_filename_format([
      "#{config_filename}.#{ext}",
      "#{config_filename}-#{instance}.#{ext}",
      "#{config_filename}-#{env}.#{ext}",
      "#{config_filename}-#{short_hostname}-#{env}-#{instance}.#{ext}",
      "#{config_filename}-#{full_hostname}-#{env}-#{instance}.#{ext}"
    ])
    |> set_vars([full_hostname: full_hostname, short_hostname: short_hostname])
    |> set_vars(params[:vars])
    |> set_options(params[:options])
    |> register_default_extensions
  end

  # CONFIGURATION LOADING
  def load_config_folder(params \\ %{}) do
    default_config_folder(params)
    |> load_config(params)
  end
  def load_config_folder(spellbook = %Spellbook{}, params = %{}) do
    spellbook
    |> set_vars(params[:vars])
    |> set_options(params[:options])
    |> load_config(params)
  end

  def load_config(params) when is_list(params) do
    Spellbook.default_config()
    |> Spellbook.load_config(params)
  end
  def load_config(spellbook = %Spellbook{}, params) when is_list(params) do
    load_config(spellbook, Map.new(params))
  end
  def load_config(spellbook = %Spellbook{}, params = %{}) do
    # load and merge available config files
    {config_files, params} = generate(spellbook, params)
    config_folder = Map.get(params, :folder, Path.join(System.cwd() || __DIR__, "config"))

    # load data from files and merge it
    {_, config} = Enum.map_reduce(
      config_files,
      %{},
      &(load_and_merge_config_file(
        spellbook,
        to_string(Path.join(config_folder, &1)),
        &2)
      )
    )

    # merge optional :config data
    # TODO: is this in the right position in the code? What should be the priority of this config?
    config = case Map.get(params, :config) do
      data when is_map(data) -> deep_merge(config, data)
      data when is_list(data) -> deep_merge(config, Map.new(data))
      nil -> config
    end

    # load and merge optional ENV vars from <FOLDER>/custom-env-variables.<EXT>
    config = load_and_merge_env_variables_file(spellbook, params, config)

    #TODO: load merge optional CLI parameters defined in <FOLDER>/<CONFIG_FILENAME>-cli-variables.<EXT>

    config
  end

  # ENVIRONMENT VARIABLES
  defp load_and_merge_env_variables_file(spellbook = %Spellbook{}, params, config) do
    config_folder = Map.get(params, :folder, Path.join(System.cwd() || __DIR__, "config"))
    config_env_filename = Map.get(params, :env_filename, @default_env_filename)

    # scan all supported extensions
    {_, config} = Enum.map_reduce(spellbook.extensions, config,
      fn({ext, _}, config) ->
        filename = Path.join(config_folder, "#{config_env_filename}.#{ext}")

        case load_config_file(spellbook, filename) do
          {:ok, data} ->
            env_config = substitute_vars(data, System.get_env())
            {filename, deep_merge(config, env_config)}
          {:error, _} -> {filename, config}
        end
      end
    )

    config
  end

  defp load_and_merge_config_file(spellbook = %Spellbook{}, filename, config = %{}) do
    load_config_file(spellbook, filename)
    |> merge_config_file_result(filename, config)
  end

  defp load_config_file(spellbook = %Spellbook{}, filename) do
    case File.read(filename) do
      {:ok, data} ->
        ext = String.downcase(String.trim_leading(Path.extname(filename), "."))
        case Map.get(spellbook.extensions, ext) do
          parser when not is_nil(parser) ->
            apply(parser, :parse, [data])
          nil ->
            Logger.debug("Error loading '#{filename}': unsupported file format")
            {:error, "unsupported file format"}
        end
      {:error, reason} ->
        case reason do
          :enoent -> nil
          true -> Logger.debug("Error loading '#{filename}': #{reason}")
        end
        {:error, reason}
    end
  end

  defp merge_config_file_result(result, filename, config = %{}) do
    case result do
      {:ok, data} -> {filename, deep_merge(config, data)}
      {:error, _} -> {filename, config}
    end
  end
end
