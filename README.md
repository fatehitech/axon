# Thalamex

Intended to run on a device connected to microcontrollers via serial port.

Firmata code for each microcontroller is maintained in the [Cortex](https://github.com/fatehitech/cortex).

It connects to Cortex via Erlang's distribution mechanism to fetch code.

It ensures that each microcontroller is identified and code loaded.

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
