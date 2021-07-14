let
    patched = import ./default.nix;
    inherit (patched) pkgs haskellPackages;
    app = haskellPackages.callCabal2nix "app" ./app { };
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
  ];
})
