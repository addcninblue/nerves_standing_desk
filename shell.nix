{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  inherit (lib) optional optionals;
  elixir = beam.packages.erlangR23.elixir_1_10;
in

  mkShell {
    buildInputs = [ elixir git pkgconf automake autoconf squashfsTools fwup gparted pkg-config ]
    ++ optional stdenv.isLinux libnotify # For ExUnit Notifier on Linux.
    ++ optional stdenv.isLinux inotify-tools # For file_system on Linux.
    ++ optional stdenv.isLinux x11_ssh_askpass # For `mix firmware.burn`.
    ++ optional stdenv.isDarwin terminal-notifier # For ExUnit Notifier on macOS.
    ++ optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
      # For file_system on macOS.
      CoreFoundation
      CoreServices
    ]);
    shellHooks = ''
      export SUDO_ASKPASS=${x11_ssh_askpass}/libexec/x11-ssh-askpass
    '';
  }
