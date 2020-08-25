# Nerves Standing Desk

Motivation: https://embedded-elixir.com/post/2019-01-18-nerves-at-home-desk-controller/

Blog Post: http://addcnin.blue:8000/2020/08/24/nerves-table/

## Getting Started

To start your Nerves app:
  * `export MIX_TARGET=my_target` or prefix every command with
    `MIX_TARGET=my_target`. For example, `MIX_TARGET=rpi3`
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`

If you're on NixOS, there's also a `default.nix` for your convenience. `nix-shell` and then the above commands will suffice.
