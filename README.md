Spellbook
=========
[![Build Status](https://travis-ci.org/alexiob/spellbook.svg?branch=master)]
(https://travis-ci.org/alexiob/spellbook)
[![Inline docs](http://inch-ci.org/github/alexiob/spellbook.svg)](http://inch-ci.org/github/alexiob/spellbook)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/alexiob/spellbook.svg)](https://beta.hexfaktor.org/github/alexiob/spellbook)
[![Hex version](https://img.shields.io/hexpm/v/spellbook.svg)](https://hex.pm/packages/spellbook)

Introduction
------------

Spellbook is an Elixir library providing dynamic hierarchical configurations loading for your application.
It is based on the ideas implemented in the Javascript [node-config](https://nodei.co/npm/config/) module.

It lets you define a set of default parameters, and extend them for different deployment environments (development, staging, production, etc.) or custom needs (client id, hostname, etc.).

Configurations are stored in default or custom folders containing [configuration files]() and can be overridden and extended by environment variables.

Custom configuration static and dynamic filenames and file formats can be added as needed.

Installation
------------

Add Spellbook as a dependency to your `mix.exs` file.

```elixir
defp deps do
  [{:spellbook, github: "alexiob/spellbook"}]
end
```

Documentation
-------------
The API reference can be found [here](https://hexdocs.pm/dumballah/api-reference.html).


Quick Start
-----------

**Read the configuration files from the standard `<CWD>/config` folder**

```elixir
config = Spellbook.load_config_folder()
```

Using `Spellbook.load_config_folder/0` by default will use the following filename templates (in the listed order and if they exist) with the `{SOMETHING}` template variables substituted:

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

Spellbook will use the default  environment (`{ENV}` = `dev`) and the full hostname of the machine the code gets executed on (`{FULL_HOSTNAME}` = `my-machine.spellbook.domain`). As the other template variables are not defined, the filenames using them are ignored. 
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
|> Spellbook.add_filename_format("clients/#{brand}.#{ext}")
|> Spellbook.load_config(
  folder: "./test/support/brand",
  config_filename: "brand-conf",
  vars: [instance: "job-processor", brand: "elixir", env: "prod", short_hostname: "worker"]
)
```

Here we specify a specific folder were to look for the configuration files (with the `folder` option), a custom configuration file name (with the `config_filename` option). The `vars` configuration field is used to define the variable values used in the filename templates. 

The `Spellbook.default_config/0` function (and the `Spellbook.load_config/0` one as well) configures the Spellbook to search for the following file templates:

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

or using the `Spellbook.get` method that supports dot notation to access elements deep down the configuration structure:

```elixir
iex> value = Spellbook.get(config, "some.value.from.config")
"a value"
```

**Use environment variables in configuration files**

Some situations rely heavily on environment variables to configure secrets and settings best left out of a codebase. Spellbook lets you use map the environment variable names into your configuration structure using a `custom-env-variables.{EXT}` file:

```json
{
  "database": {
    "username": "DB_USERNAME",
    "password": "DB_PASSWORD"
  }
}
```

If the `DB_USERNAME` and `DB_PASSWORD` environment variable exist, they would override the values for `database.username` and `database.password` in the configuration.

Custom environment variables have precedence and override all configuration files, including `local.json`.

License
-------

Spellbook is provided under the [MIT license](LICENSE)