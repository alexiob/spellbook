defmodule Spellbook do
  @moduledoc """
  Introduction
  ------------

  Spellbook is an Elixir library providing dynamic hierarchical configurations loading for your application.
  It is based on the ideas implemented in the Javascript [node-config](https://nodei.co/npm/config/) module.

  It lets you define a set of default parameters, and extend them for different deployment
  environments (development, staging, production, etc.) or custom needs (client id, hostname, etc.).

  Configurations are stored in default or custom folders containing [configuration files]()
  and can be overridden and extended by environment variables.

  Custom configuration static and dynamic filenames and file formats can be added as needed.

  Quick Start
  -----------

  **Read the configuration files from the standard `<CWD>/config` folder**

  ```elixir
  config = Spellbook.load_config_folder()
  ```

  Using `Spellbook.load_config_folder/0` by default will use the following filename
  templates (in the listed order and if they exist) with the `{SOMETHING}` template
  variables substituted:

  ```
  <CWD>/config/default.{EXT}
  <CWD>/config/default-{INSTANCE}.{EXT}
  <CWD>/config/{ENV}.{EXT}
  <CWD>/config/{ENV}-{INSTANCE}.{EXT}
  <CWD>/config/{SHORT_HOSTNAME}.{EXT}
  <CWD>/config/{SHORT_HOSTNAME}-{INSTANCE}.{EXT}
  <CWD>/config/{SHORT_HOSTNAME}-{ENV}.{EXT}
  <CWD>/config/{SHORT_HOSTNAME}-{ENV}-{INSTANCE}.{EXT}
  <CWD>/config/{FULL_HOSTNAME}.{EXT}
  <CWD>/config/{FULL_HOSTNAME}-{INSTANCE}.{EXT}
  <CWD>/config/{FULL_HOSTNAME}-{ENV}.{EXT}
  <CWD>/config/{FULL_HOSTNAME}-{ENV}-{INSTANCE}.{EXT}
  <CWD>/config/local.{EXT}
  <CWD>/config/local-{INSTANCE}.{EXT}
  <CWD>/config/local-{ENV}.{EXT}
  <CWD>/config/local-{ENV}-{INSTANCE}.{EXT}
  <CWD>/config/custom-env-variables.{EXT}
  ```

  Spellbook will use the default  environment (`{ENV}` = `dev`) and the full hostname
  of the machine the code gets executed on (`{FULL_HOSTNAME}` = `my-machine.spellbook.domain`).
  As the other template variables are not defined, the filenames using them are ignored.
  The resulting filenames searched/merged will be:

  ```
  <CWD>/config/default.json
  <CWD>/config/default.yaml
  <CWD>/config/dev.json
  <CWD>/config/dev.yaml
  <CWD>/config/my-machine.spellbook.domain.json
  <CWD>/config/my-machine.spellbook.domain.yaml
  <CWD>/config/my-machine.spellbook.domain-dev.json
  <CWD>/config/my-machine.spellbook.domain-dev.yaml
  <CWD>/config/local.json
  <CWD>/config/local.yaml
  <CWD>/config/local-dev.json
  <CWD>/config/local-dev.yaml
  <CWD>/config/custom-env-variables.json
  <CWD>/config/custom-env-variables.yaml
  ```

  By default Spellbook supports JSON and YAML file formats.

  **Read brand's configuration from a specific folder with custom settings for a specific client**

  ```elixir
  config = Spellbook.default_config()
  |> Spellbook.add_filename_format("clients/%{brand}.%{ext}")
  |> Spellbook.load_config(
    folder: "./test/support/brand",
    config_filename: "brand-conf",
    vars: [instance: "job-processor", brand: "elixir", env: "prod", short_hostname: "worker"]
  )
  ```

  Here we specify a specific folder were to look for the configuration files
  (with the `folder` option), a custom configuration file name (with the `config_filename` option).
  The `vars` configuration field is used to define the variable values used in
  the filename templates.

  The `Spellbook.default_config/0` function (and the `Spellbook.load_config/0` one as well)
  configures the Spellbook to search for the following file templates:

  ```
  ./test/support/brand/{CONFIG\_FILENAME}.{EXT}
  ./test/support/brand/{CONFIG\_FILENAME}-{INSTANCE}.{EXT}
  ./test/support/brand/{CONFIG\_FILENAME}-{ENV}.{EXT}
  ./test/support/brand/{CONFIG\_FILENAME}-{SHORT_HOSTNAME}-{ENV}-{INSTANCE}.{EXT}
  ./test/support/brand/{CONFIG\_FILENAME}-{FULL_HOSTNAME}-{ENV}-{INSTANCE}.{EXT}
  ./test/support/brand/clients/{BRAND}.{EXT}
  ./test/support/brand/custom-env-variables.{EXT}
  ```

  In this case the searched/merged files will be:

  ```
  ./test/support/brand/brand-conf.json
  ./test/support/brand/brand-conf.yaml
  ./test/support/brand/brand-conf-job-processor.json
  ./test/support/brand/brand-conf-job-processor.yaml
  ./test/support/brand/brand-conf-prod.json
  ./test/support/brand/brand-conf-prod.yaml
  ./test/support/brand/brand-conf-worker-prod-job-processor.json
  ./test/support/brand/brand-conf-worker-prod-job-processor.yaml
  ./test/support/brand/brand-conf-worker1.spellbook.domain-prod-job-processor.json
  ./test/support/brand/brand-conf-worker1.spellbook.domain-prod-job-processor.yaml
  ./test/support/brand/clients/elixir.json
  ./test/support/brand/clients/elixir.yaml
  ./test/support/brand/custom-env-variables.json
  ./test/support/brand/custom-env-variables.yaml
  ```

  **Get a value out of a Spellbook configuration**

  A configuration is just a Map.

  ```elixir
  iex> config = Spellbook.load_config_folder()
  %{ "some" => %{ "value" => %{ "from" => %{ "config" => "a value" }}}}
  iex> is_map(config) == true
  true
  ```

  You can access the configuration values using the standard language features

  ```elixir
  iex> value = config["some"]["value"]["from"]["config"]
  "a value"
  ```

  or using the `Spellbook.get` method that supports dot notation to access elements
  deep down the configuration structure:

  ```elixir
  iex> value = Spellbook.get(config, "some.value.from.config")
  "a value"
  ```

  **Use environment variables in configuration files**

  Some situations rely heavily on environment variables to configure secrets and
  settings best left out of a codebase. Spellbook lets you use map the environment
  variable names into your configuration structure using a `custom-env-variables.{EXT}` file:

  ```json
  {
    "database": {
      "username": "DB_USERNAME",
      "password": "DB_PASSWORD"
    }
  }
  ```

  If the `DB_USERNAME` and `DB_PASSWORD` environment variable exist, they would
  override the values for `database.username` and `database.password` in the configuration.

  Custom environment variables have precedence and override all configuration
  files, including `local.json`.
  """

  @default_config_filename "config"
  @default_env_filename "custom-env-variables"

  defstruct filename_formats: [],
            extensions: %{
              "json" => Spellbook.Parser.JSON,
              "yaml" => Spellbook.Parser.YAML
            },
            vars: %{
              env: to_string(Mix.env())
            },
            options: %{
              ignore_invalid_filename_formats: true
            }

  require Logger
  require Spellbook.Interpolation

  # UTILITIES

  @doc """
  Performs a deep merge of two maps.

  ## Examples
      iex> Spellbook.deep_merge(%{"a" => %{"b" => "1", "c" => [1,2,3]}}, %{"a" => %{"b" => "X"}})
      %{"a" => %{"b" => "X", "c" => [1, 2, 3]}}
  """
  @spec deep_merge(left :: Map.t(), right :: Map.t()) :: Map.t()
  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end

  defp deep_resolve(_key, _left, right) do
    right
  end

  @doc """
  Performs a deep merge of a configuration into an application environment.
  """
  @spec apply_config_to_application_env(
          config :: Map.t(),
          config_key :: String.t(),
          atom | nil,
          atom | nil
        ) :: :ok
  def apply_config_to_application_env(config, config_key, app_name \\ nil, env_key \\ nil) do
    env_config = Map.get(config, config_key)

    app_name =
      case is_nil(app_name) do
        true -> Application.get_application(__MODULE__)
        false -> app_name
      end

    env_key =
      case is_nil(env_key) do
        true -> String.to_existing_atom("Elixir." <> config_key)
        false -> env_key
      end

    env = Application.fetch_env!(app_name, env_key)

    env =
      Enum.reduce(Map.keys(env_config), env, fn k, env ->
        Keyword.put(env, String.to_atom(k), Map.get(env_config, k))
      end)

    Application.put_env(app_name, env_key, env)

    :ok
  end

  @doc """
  Performs a deep substitution of variables used as map values.

  ## Examples
      iex> Spellbook.substitute_vars(%{"a" => %{"b" => "VAR", "c" => "NOT_A_VAR"}}, %{"VAR" => "spellbook"})
      %{"a" => %{"b" => "spellbook", "c" => "NOT_A_VAR"}}
  """
  @spec substitute_vars(config :: Map.t(), vars :: Map.t()) :: Map.t()
  def substitute_vars(config, vars) do
    Map.merge(config, config, fn key, config, _config ->
      substitute_vars_resolve(key, config, vars)
    end)
  end

  defp substitute_vars_resolve(_key, config, vars) when is_map(config) do
    substitute_vars(config, vars)
  end

  defp substitute_vars_resolve(_key, config, vars) do
    Map.get(vars, config, config)
  end

  defp get_hostnames do
    {:ok, full_hostname} = :inet.gethostname()
    full_hostname = to_string(full_hostname)
    short_hostname = to_string(String.split(full_hostname, ".", parts: 1))

    short_hostname =
      case short_hostname do
        ^full_hostname -> nil
      end

    {full_hostname, short_hostname}
  end

  defp set_config_name(params) when is_map(params) do
    vars = Map.get(params, :vars, Keyword.new())

    vars =
      case Map.has_key?(params, :config_filename) do
        true -> Keyword.put_new(vars, :config_filename, Map.get(params, :config_filename))
        false -> vars
      end

    vars =
      case Keyword.has_key?(vars, :config_filename) do
        false -> [{:config_filename, @default_config_filename}] ++ vars
        true -> vars
      end

    Map.put(params, :vars, vars)
  end

  @doc """
  Retrieves a configuration value.

  This function supports dot notation, so you can retrieve values
  from deeply nested keys, like "database.config.password".

  ## Examples
      iex> Spellbook.get(%{"a" => %{"b" => "1", "c" => [1,2,3]}}, "a.b")
      "1"
  """
  @spec get(config :: Map.t(), key :: String.t()) :: any
  def get(config, key) when is_map(config) do
    DotNotes.get(config, key)
  end

  # FILE FORMATS
  @doc """
  Adds a filename format to the list of templates to be used to generate
  the list of files to be searched when the configuration is loaded.

  Filename formats can contain template variables specified using the following interpolation format (`%{VARIABLE}`):
  * `"special-%{env}.%{ext}"`
  * `"config-%{username}-%{role}.json"`

  Files are loaded in the order you specify the filename formats.

      config = Spellbook.default_config()
      |> Spellbook.add_filename_format("clients/%{brand}.%{ext}")
      |> Spellbook.add_filename_format(["clients/special/%{brand}-%{version}.%{ext}", "clients/external-%{brand}.%{ext}"])

  """
  # @spec add_filename_format(spellbook :: Spellbook, filename_formats :: [String.t]) :: Spellbook
  def add_filename_format(spellbook, filename_formats) when is_list(filename_formats) do
    current_filename_formats = Map.get(spellbook, :filename_formats, [])
    Map.put(spellbook, :filename_formats, current_filename_formats ++ filename_formats)
  end

  @spec add_filename_format(spellbook :: Spellbook, filename_formats :: String.t()) :: Spellbook
  def add_filename_format(spellbook, filename_format) do
    current_filename_formats = Map.get(spellbook, :filename_formats, [])
    Map.put(spellbook, :filename_formats, current_filename_formats ++ [filename_format])
  end

  # FILE LIST GENERATOR
  def generate(spellbook = %Spellbook{}, params) do
    params =
      %{config_filename: @default_config_filename, vars: Keyword.new()}
      |> Map.merge(params)
      |> set_config_name()

    merged_vars =
      spellbook
      |> Map.get(:vars)
      |> Map.merge(Map.new(Map.get(params, :vars, Keyword.new())))
      |> Map.to_list()
      |> Enum.filter(fn v -> !is_nil(elem(v, 1)) end)
      |> Map.new()

    config_files =
      spellbook.filename_formats
      |> Enum.flat_map(fn format ->
        Enum.map(
          spellbook.extensions,
          fn {extension, _} ->
            interpolate(spellbook, merged_vars, format, extension)
          end
        )
      end)
      |> Enum.filter(&(!is_nil(&1)))

    {config_files, params}
  end

  defp interpolate(spellbook, merged_vars, format, extension) do
    merged_vars = Map.put(merged_vars, :ext, extension)

    case Spellbook.Interpolation.interpolate(
           Spellbook.Interpolation.to_interpolatable(format),
           merged_vars
         ) do
      {:ok, interpolated_string} ->
        interpolated_string

      {:missing_bindings, _incomplete_string, missing_bindings} ->
        missing_bindings_handler(spellbook, format, missing_bindings)
    end
  end

  defp missing_bindings_handler(spellbook, format, missing_bindings) do
    case spellbook.options.ignore_invalid_filename_formats do
      false ->
        raise ArgumentError,
          message: "Filename format #{format} missing bindings: #{missing_bindings}"

      true ->
        # Logger.debug("Skipping filename format: #{format}")
        nil
    end
  end

  # VARIABLES
  @doc """
  Sets some variable to be used during filenames list generation.
  """
  @spec set_vars(spellbook :: %Spellbook{}, values :: maybe_improper_list()) :: %Spellbook{}
  def set_vars(spellbook = %Spellbook{}, values) when is_list(values) do
    Enum.reduce(values, spellbook, fn value, spellbook -> set_var(spellbook, value) end)
  end

  @doc """
  Sets a variable to be used during filenames list generation using a 2 elements
  tuple.
  """
  @spec set_var(spellbook :: %Spellbook{}, {name :: String.t(), value :: any}) :: %Spellbook{}
  def set_var(spellbook = %Spellbook{}, {name, value}) do
    set_var(spellbook, name, value)
  end

  @doc """
  Sets a variable to be used during filenames list generation.
  """
  @spec set_var(spellbook :: %Spellbook{}, name :: String.t(), value :: any) :: %Spellbook{}
  def set_var(spellbook = %Spellbook{}, name, value) do
    Map.put(spellbook, :vars, Map.put(Map.get(spellbook, :vars), name, value))
  end

  # OPTIONS
  @doc """
  Sets Spellbook options. Option names are atoms.

  Valid options are:
  * `:folder`: folder where to find the configuration. Defaults to `\#{Path.join(File.cwd!(), "config")}`.
  * `:config_filename`: name of the configuration file, default to `"config"`.
  * `:ignore_invalid_filename_formats`: defauts to `true`. Set it to `false` if
  you want to raise an exception if a file in the generated filenames list is not found.
  * `:config`: optional configuration Map or Keyword list to be merged into the
  final configuration. Takes precedence on everything except the environment variables.
  """
  @spec set_options(spellbook :: %Spellbook{}, options :: nil | list | Map.t()) :: %Spellbook{}
  def set_options(spellbook = %Spellbook{}, options) when is_nil(options) do
    spellbook
  end

  def set_options(spellbook = %Spellbook{}, options) when is_list(options) do
    set_options(spellbook, Map.new(options))
  end

  def set_options(spellbook = %Spellbook{}, options) when is_map(options) do
    Map.put(spellbook, :options, Map.merge(Map.get(spellbook, :options), options))
  end

  # EXTENSIONS
  @doc """
  Registers an config file format extension and its parser.

      extensions = %{
        "csv" => Crazy.Parser.CSV
      }
      Spellbook.register_extensions(spellbook, extensions)
  """
  @spec register_extensions(spellbook :: %Spellbook{}, extensions :: Map.t()) :: %Spellbook{}
  def register_extensions(spellbook = %Spellbook{}, extensions) do
    Map.put(spellbook, :extensions, Map.merge(spellbook.extensions, extensions))
  end

  # DEFAULT CONFIG FOLDER
  @doc """
  Sets up the default configuration for reading application configuration from a folder.
  """
  @spec default_config_folder(params :: keyword()) :: %Spellbook{}
  def default_config_folder(params) when is_list(params) do
    default_config_folder(%Spellbook{}, Map.new(params))
  end

  @doc """
  Sets up the default configuration for reading application configuration from a folder.
  """
  @spec default_config_folder(params :: Map.t()) :: %Spellbook{}
  def default_config_folder(params) when is_map(params) do
    default_config_folder(%Spellbook{}, params)
  end

  @doc """
  Sets up the default configuration for reading application configuration from a folder.

  The valid `params` are:
  * `vars`: Keyword or Keyword list of variables to be used in the filenames list generation.
  * `options`: map with Spellbook options

  The default filename formats are:

  ```json
  <CWD>/config/default.{EXT}
  <CWD>/config/default-{INSTANCE}.{EXT}
  <CWD>/config/{ENV}.{EXT}
  <CWD>/config/{ENV}-{INSTANCE}.{EXT}
  <CWD>/config/{SHORT_HOSTNAME}.{EXT}
  <CWD>/config/{SHORT_HOSTNAME}-{INSTANCE}.{EXT}
  <CWD>/config/{SHORT_HOSTNAME}-{ENV}.{EXT}
  <CWD>/config/{SHORT_HOSTNAME}-{ENV}-{INSTANCE}.{EXT}
  <CWD>/config/{FULL_HOSTNAME}.{EXT}
  <CWD>/config/{FULL_HOSTNAME}-{INSTANCE}.{EXT}
  <CWD>/config/{FULL_HOSTNAME}-{ENV}.{EXT}
  <CWD>/config/{FULL_HOSTNAME}-{ENV}-{INSTANCE}.{EXT}
  <CWD>/config/local.{EXT}
  <CWD>/config/local-{INSTANCE}.{EXT}
  <CWD>/config/local-{ENV}.{EXT}
  <CWD>/config/local-{ENV}-{INSTANCE}.{EXT}
  <CWD>/config/custom-env-variables.{EXT}
  ```
  """
  @spec default_config_folder(spellbook :: %Spellbook{}, params :: Map.t()) :: %Spellbook{}
  def default_config_folder(spellbook = %Spellbook{} \\ %Spellbook{}, params \\ %{}) do
    {full_hostname, short_hostname} = get_hostnames()

    params = set_config_name(params)

    spellbook
    |> add_filename_format([
      "default.%{ext}",
      "default-%{instance}.%{ext}",
      "%{env}.%{ext}",
      "%{env}-%{instance}.%{ext}",
      "%{short_hostname}.%{ext}",
      "%{short_hostname}-%{instance}.%{ext}",
      "%{short_hostname}-%{env}.%{ext}",
      "%{short_hostname}-%{env}-%{instance}.%{ext}",
      "%{full_hostname}.%{ext}",
      "%{full_hostname}-%{instance}.%{ext}",
      "%{full_hostname}-%{env}.%{ext}",
      "%{full_hostname}-%{env}-%{instance}.%{ext}",
      "local.%{ext}",
      "local-%{instance}.%{ext}",
      "local-%{env}.%{ext}",
      "local-%{env}-%{instance}.%{ext}"
    ])
    |> set_vars(full_hostname: full_hostname, short_hostname: short_hostname)
    |> set_vars(params[:vars])
    |> set_options(params[:options])
  end

  # DEFAULT CONFIG
  @doc """
  Sets up the default configuration for reading a generic configuration set of files.

  Accepts a list
  """
  def default_config(params) when is_list(params) do
    default_config(%Spellbook{}, Map.new(params))
  end

  def default_config(params) when is_map(params) do
    default_config(%Spellbook{}, params)
  end

  @doc """
  Sets up the default configuration for reading a generic configuration set of files.

  The valid `params` are:
  * `vars`: Keyword or Keyword list of variables to be used in the filenames list generation.
  * `options`: map with Spellbook options

  The default filename formats are:

  ```json
  <FOLDER>/{CONFIG\_FILENAME}.{EXT}
  <FOLDER>/{CONFIG\_FILENAME}-{INSTANCE}.{EXT}
  <FOLDER>/{CONFIG\_FILENAME}-{ENV}.{EXT}
  <FOLDER>/{CONFIG\_FILENAME}-{SHORT_HOSTNAME}-{ENV}-{INSTANCE}.{EXT}
  <FOLDER>/{CONFIG\_FILENAME}-{FULL_HOSTNAME}-{ENV}-{INSTANCE}.{EXT}
  <FOLDER>/custom-env-variables.{EXT}
  ```
  """
  @spec default_config(spellbook :: %Spellbook{}, params :: Map.t()) :: %Spellbook{}
  def default_config(spellbook = %Spellbook{} \\ %Spellbook{}, params \\ %{}) do
    {full_hostname, short_hostname} = get_hostnames()

    params = set_config_name(params)

    spellbook
    |> add_filename_format([
      "%{config_filename}.%{ext}",
      "%{config_filename}-%{instance}.%{ext}",
      "%{config_filename}-%{env}.%{ext}",
      "%{config_filename}-%{short_hostname}-%{env}-%{instance}.%{ext}",
      "%{config_filename}-%{full_hostname}-%{env}-%{instance}.%{ext}"
    ])
    |> set_vars(full_hostname: full_hostname, short_hostname: short_hostname)
    |> set_vars(params[:vars])
    |> set_options(params[:options])
  end

  # CONFIGURATION LOADING
  @doc """
  Creates a Spellbook with the default config folder filenames list and loads them into a configuration map
  """
  @spec load_config_folder(params :: Map.t()) :: Map.t()
  def load_config_folder(params \\ %{}) do
    params
    |> default_config_folder()
    |> load_config(params)
  end

  @doc """
  Creates a Spellbook with the default config folder filenames list and loads them into a configuration map
  """
  @spec load_config_folder(spellbook :: %Spellbook{}, params :: Map.t()) :: Map.t()
  def load_config_folder(spellbook = %Spellbook{}, params) do
    spellbook
    |> set_vars(params[:vars])
    |> set_options(params[:options])
    |> load_config(params)
  end

  @doc """
  Creates a Spellbook with the default config filenames list and loads them into a configuration map.
  """
  @spec load_default_config(params :: list) :: Map.t()
  def load_default_config(params) when is_list(params) do
    params
    |> default_config()
    |> load_config(params)
  end

  @doc """
  Loads the configuration files from the provided Spellbook.
  """
  @spec load_config(spellbook :: %Spellbook{}, params :: maybe_improper_list()) :: Map.t()
  def load_config(spellbook = %Spellbook{}, params) when is_list(params) do
    load_config(spellbook, Map.new(params))
  end

  @doc """
  Loads the configuration files from the provided Spellbook.
  """
  @spec load_config(spellbook :: %Spellbook{}, params :: Map.t()) :: Map.t()
  def load_config(spellbook = %Spellbook{}, params) do
    # load and merge available config files
    {config_files, params} = generate(spellbook, params)
    config_folder = Map.get(params, :folder, Path.join(File.cwd!() || __DIR__, "config"))

    # load data from files and merge it
    {_, config} =
      Enum.map_reduce(
        config_files,
        %{},
        &load_and_merge_config_file(
          spellbook,
          to_string(Path.join(config_folder, &1)),
          &2
        )
      )

    # merge optional :config data
    # TODO: is this in the right position in the code? What should be the priority of this config?
    config =
      case Map.get(params, :config) do
        data when is_map(data) -> deep_merge(config, data)
        data when is_list(data) -> deep_merge(config, Map.new(data))
        nil -> config
      end

    # load and merge optional ENV vars from <FOLDER>/custom-env-variables.<EXT>
    config = load_and_merge_env_variables_file(spellbook, params, config)

    # TODO: load merge optional CLI parameters defined in <FOLDER>/<CONFIG_FILENAME>-cli-variables.<EXT>

    config
  end

  # ENVIRONMENT VARIABLES
  defp load_and_merge_env_variables_file(spellbook = %Spellbook{}, params, config) do
    config_folder = Map.get(params, :folder, Path.join(File.cwd!() || __DIR__, "config"))
    config_env_filename = Map.get(params, :env_filename, @default_env_filename)

    # scan all supported extensions
    {_, config} =
      Enum.map_reduce(spellbook.extensions, config, fn {ext, _}, config ->
        filename = Path.join(config_folder, "#{config_env_filename}.#{ext}")

        case load_config_file(spellbook, filename) do
          {:ok, data} ->
            env_config = substitute_vars(data, System.get_env())
            {filename, deep_merge(config, env_config)}

          {:error, _} ->
            {filename, config}
        end
      end)

    config
  end

  defp load_and_merge_config_file(spellbook = %Spellbook{}, filename, config = %{}) do
    spellbook
    |> load_config_file(filename)
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
