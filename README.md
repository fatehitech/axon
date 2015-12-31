# Thalamex

Can be configured in standalone mode or in default mode.

The default mode is such that the device is connected to Firmata devices via serial port.

Firmata code for each microcontroller is maintained in the [Cortex](https://github.com/fatehitech/cortex).

The code for Standalone mode also would be in the Cortex.

It connects to Cortex via Erlang's distribution mechanism to fetch code, make calls, and send messages.

Cortex also allows the developer to interface with InfluxDB, defining series and pushing data to them.

**Identification** of each MCU occurs based on the firmware name reported by Firmata.

Firmware name can be set by changing the Arduino sketch filename.

In standalone mode, the name is defined in the `config.exs` file.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add thalamex to your list of dependencies in `mix.exs`:

        def deps do
          [{:thalamex, "~> 0.0.1"}]
        end

  2. Ensure thalamex is started before your application:

        def application do
          [applications: [:thalamex]]
        end

## Configuration

We'll assume Cortex is running and accessible at cortex@example.com

### Standalone Mode

Create a **Thing** in Cortex, e.g. "GarageDoor", then configure your mix app like so:

```elixir
config :thalamex,
  cortex: :"cortex@synapse",
  standalone: true,
  standalone_name: "GarageDoor"
```

### Firmata Mode

Create as many **Things** in Cortex ensuring that the name matches the sketch name (do this by renaming StandardFirmata.ino).

For example, you have 2 devices and you have two **Thing** entries, "Plants.ino" and "Solar.ino", and plug them in via a USB powered hub.

Configure your mix app like so:

```elixir
config :thalamex,
  cortex: :"cortex@synapse"
```

It's actually simpler.

## Platform

[Nerves](http://nerves-project.org) on Beaglebone Black or Raspberry Pi makes an excellent platform for this.
