let
  nixpkgs = import <nixpkgs> {};
  inherit (nixpkgs) pkgs;

  gmp = import ./ghc-flavors/gmp.nix;
  native = import ./ghc-flavors/native-bignum.nix;
  nativeWithPatch = import ./ghc-flavors/native-bignum-with-patch.nix;

  genStatic = import ./gen-static.nix;
in {
  gmp = genStatic { mypkgs = gmp; withGmp = true; };
  native = genStatic { mypkgs = native; };
  nativeWithPatch = genStatic { mypkgs = nativeWithPatch; };
}
