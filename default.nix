let
    inherit (import <nixpkgs> {}) pkgs;
    inherit (pkgs) lib;

    flavors = {
        gmp = import ./ghc-flavors/gmp.nix;
        nativeBignum = import ./ghc-flavors/native-bignum.nix;
        nativeBignumWithPatch = import ./ghc-flavors/native-bignum-with-patch.nix;
    };

    verboseOpt = "--ghc-option=-v";

    statify =
        { pkgs, haskellPackages }:
        { app, withGmp ? false, verbose ? false, extraFlags ? [] }:
        let 
            app' = haskellPackages.callCabal2nix app.name app.src {};
            gmpLibOpt = "--ghc-option=-optl=-L${pkgs.gmp6.override { withStatic = true; }}/lib";
        in
            pkgs.haskell.lib.overrideCabal app' (drv: {
              enableSharedExecutables = false;
              enableSharedLibraries = false;
              configureFlags = [
                "--ghc-option=-optl=-static"
                "--ghc-option=-optl=-L${pkgs.glibc.static}/lib"
                "--ghc-option=-optl=-L${pkgs.zlib.static}/lib"
                "--ghc-option=-optl=-L${pkgs.libffi.overrideAttrs (old: { dontDisableStatic = true; })}/lib"
              ] ++ pkgs.lib.optional verbose verboseOpt 
                ++ pkgs.lib.optional withGmp gmpLibOpt
                ++ extraFlags;
            });
in {
    inherit statify flavors;
    genStatic =
        builtins.mapAttrs
            (name: value: statify (lib.getAttrs ["pkgs" "haskellPackages"] value))
            flavors;
}
