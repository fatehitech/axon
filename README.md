# Thalamex

Can be configured in standalone mode or in default mode.

The default mode is such that the device is connected to Firmata devices via serial port.

Firmata code for each microcontroller is maintained in the [Cortex](https://github.com/fatehitech/cortex).

The code for Standalone mode also would be in the Cortex.

It connects to Cortex via Erlang's distribution mechanism to fetch code, make calls, and send messages.

Cortex also allows the developer to interface with InfluxDB, defining series and pushing data to them.

**Identification** of each MCU occurs based on the firmware name reported by Firmata.

Firmware name can be set by changing the Arduino sketch filename.

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
