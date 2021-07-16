let
  nixpkgs = import <nixpkgs> {};

  pinnedPkgs = import ../pinned.nix;
  
  patch = ./ghc901-nativebignum.patch;
  
  patchedPkgs = nixpkgs.runCommand "nixos-21.05-2021-07-01-ghc901-nativebignum"
     {
       inherit pinnedPkgs patch;
     }
     ''
       cp -r $pinnedPkgs $out
       chmod -R +w $out
       echo "Applying patch $patch";
       patch -d $out -p1 < "$patch";
     '';

  patchedNixpkgs = import patchedPkgs {};

  inherit (patchedNixpkgs) pkgs;

  haskellPackages = pkgs.haskell.packages.native-bignum.ghc901;

  ghc901 = pkgs.haskell.compiler.native-bignum.ghc901;
in {
    pkgs = pkgs;
    haskellPackages = haskellPackages;
    ghc901 = ghc901;
}
