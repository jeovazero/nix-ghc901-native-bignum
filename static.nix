let
  nixpkgs = import <nixpkgs> {};
  inherit (nixpkgs) pkgs;

  utils = import ./default.nix;
  inherit (utils) genStatic;

  app = { name = "app"; src = ./app; };

  params = { app = app; verbose = true; };
in
    builtins.mapAttrs
        (name: statify: statify (params // { withGmp = name == "gmp"; }))
        genStatic
