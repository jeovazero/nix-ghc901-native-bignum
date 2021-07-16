let
  nixpkgs = import <nixpkgs> {};
  inherit (nixpkgs) pkgs;

  gmp = import ./ghc-flavors/gmp.nix;
  native = import ./ghc-flavors/native-bignum.nix;
  nativeWithPatch = import ./ghc-flavors/native-bignum-with-patch.nix;
in {
  gmp = pkgs.mkShell {
    nativeBuildInputs = [ gmp.ghc901 ];
  };
  native = pkgs.mkShell {
    nativeBuildInputs = [ native.ghc901 ];
  };
  nativeWithPatch = pkgs.mkShell {
    nativeBuildInputs = [ nativeWithPatch.ghc901 ];
  };
}
