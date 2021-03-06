defmodule SpellbookTest do
  use ExUnit.Case
  require Spellbook
  doctest Spellbook, except: [:moduledoc]

  @test_env_port "123"
  @test_env_pi "3.14"
  @test_env_active "false"

  test "generate" do
    params = %{:vars => [instance: 0, brand: "alexiob", env: "dev"]}
    {config_files, params} = Spellbook.generate(Spellbook.default_config(), params)

    assert length(config_files) == 8
    assert Map.get(params, :config_filename) == "config"
  end

  test "load_config_folder without config" do
    config = Spellbook.load_config_folder()

    assert is_map(config)
    assert Map.keys(config) == []
  end

  test "load_config_folder with simple config" do
    config = Spellbook.load_config_folder(vars: [instance: 0, brand: "alexiob", env: "dev"])

    assert is_map(config)
    assert Map.keys(config) == []
  end

  test "load_config_folder" do
    System.put_env("PORT", @test_env_port)
    System.put_env("PI", @test_env_pi)
    System.put_env("ACTIVE", @test_env_active)

    config =
      Spellbook.load_config_folder(
        folder: "./test/support/config",
        vars: [instance: 0, brand: "alexiob", env: "dev", short_hostname: "localhost"],
        options: %{ignore_invalid_filename_formats: false}
      )

    assert is_map(config)
    assert Map.has_key?(config, "env")
    assert Map.get(config, "env") == "dev"
    assert Map.get(config, "overwritten") == "local"
    assert Spellbook.get(config, "null") == nil
    assert Spellbook.get(config, "deep.structure.added_by") == "dev"
    assert Spellbook.get(config, "from.yaml") == true
    assert Spellbook.get(config, "deep.structure.env.json") != "PATH"
    assert Spellbook.get(config, "deep.structure.env.yaml") != "USER"
    assert Spellbook.get(config, "deep.structure.env.json_int") == String.to_integer(@test_env_port)
    assert Spellbook.get(config, "deep.structure.env.json_float") == String.to_float(@test_env_pi)
    assert Spellbook.get(config, "deep.structure.env.json_bool") == false
  end

  test "load_config with custom filename and extra filename format" do
    config =
      Spellbook.default_config()
      |> Spellbook.add_filename_format("clients/%{brand}.%{ext}")
      |> Spellbook.load_config(
        folder: "./test/support/brand",
        config_filename: "brand-conf",
        vars: [instance: "job-processor", brand: "elixir", env: "dev", short_hostname: "worker"]
      )

    assert is_map(config)
    assert Spellbook.get(config, "name") == "elixir"
    assert Spellbook.get(config, "description") == "A real brand"
  end

  test "load_config with standard filename" do
    config =
      Spellbook.load_default_config(
        folder: "./test/support/brand",
        vars: [instance: "2"]
      )

    assert is_map(config)
    assert Spellbook.get(config, "name") == "config"
  end

  test "load_config with standard filename and custom Spellbook" do
    config =
      Spellbook.default_config()
      |> Spellbook.load_config(
        folder: "./test/support/brand",
        vars: [instance: "2"]
      )

    assert is_map(config)
    assert Spellbook.get(config, "name") == "config"
  end

  test "load_config with standard filename and custom config argument" do
    config =
      Spellbook.load_default_config(
        folder: "./test/support/brand",
        vars: [instance: "3"],
        config: [{"name", "custom"}]
      )

    assert is_map(config)
    assert Spellbook.get(config, "name") == "custom"
  end
end
