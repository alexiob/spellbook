Spellbook
=========
[![Build Status](https://travis-ci.org/alexiob/spellbook.svg?branch=master)]
(https://travis-ci.org/alexiob/spellbook)

Introduction
------------

Spellbook is an Elixir library providing dynamic hierarchical configurations loading for your application.
It is based on the ideas implemented in the Javascript [node-config](https://nodei.co/npm/config/) module.

It lets you define a set of default parameters, and extend them for different deployment environments (development, staging, production, etc.) or custom needs (client id, hostname, etc.).

Configurations are stored in default or custom folders containing [configuration files]() and can be overridden and extended by environment variables.

Custom configuration static and dynamic filenames and file formats can be added as needed.

Quick Start
-----------

**Read the configuration files from ``<CWD>/config`**

```elixir
config = Spellbook.load_config_folder()
```

The resulting config will be a merge of all the following files, in the following order, if they exist:

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

**Read brand configuration from a specific folder, with a custom configuration for a specific client**

```elixir
config = Spellbook.default_config()
|> Spellbook.add_filename_format("clients/#{brand}.#{ext}")
|> Spellbook.load_config(
  folder: "./test/support/brand",
  config_filename: "brand",
  vars: [instance: "1", brand: "elixir"]
)
```

The loaded files will be:

```
./test/support/brand/{CONFIG\_FILENAME}.{EXT}
./test/support/brand/{CONFIG\_FILENAME}-{INSTANCE}.{EXT}
./test/support/brand/{CONFIG\_FILENAME}-{ENV}.{EXT}
./test/support/brand/{CONFIG\_FILENAME}-{SHORT_HOSTNAME}-{ENV}-{INSTANCE}.{EXT}
./test/support/brand/{CONFIG\_FILENAME}-{FULL_HOSTNAME}-{ENV}-{INSTANCE}.{EXT}
./test/support/brand/custom-env-variables.{EXT}
```

**Get a configuration value out of a Spellbook**

```elixir
config = Spellbook.load_config_folder()
# config = %{ "some" => %{ "value" => %{ "from" => %{ "config" => "a value" }}}}
value = Spellbook.config_get(config, "some.value.from.config")
value == "a value"
```

The `Spellbook.config_get` method retrieves a configuration value and supports dot notation do access elements deep down the configuration structure.

----------

```elixir
config = Spellbook.load_config(
  folder: "./test/support/brand",
  vars: [instance: "2", ]
)
```

```elixir
config = Spellbook.load_config_folder(
  vars: [instance: 0, brand: "alexiob", env: "dev"]
)
```
