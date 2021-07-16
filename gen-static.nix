{ mypkgs, withGmp ? false }:
let
    inherit (mypkgs) pkgs haskellPackages;
    app = haskellPackages.callCabal2nix "app" ./app { };
    gmpLib = "--ghc-option=-optl=-L${pkgs.gmp6.override { withStatic = true; }}/lib";
in
pkgs.haskell.lib.overrideCabal app (drv: {
  enableSharedExecutables = false;
  enableSharedLibraries = false;
  configureFlags = [
    "--ghc-option=-v"
    "--ghc-option=-optl=-static"
    "--ghc-option=-optl=-L${pkgs.glibc.static}/lib"
    "--ghc-option=-optl=-L${pkgs.zlib.static}/lib"
    "--ghc-option=-optl=-L${pkgs.libffi.overrideAttrs (old: { dontDisableStatic = true; })}/lib"
  ] ++ pkgs.lib.optional withGmp gmpLib;
})
