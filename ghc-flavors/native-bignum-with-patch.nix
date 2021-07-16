let
  nixpkgs = import <nixpkgs> {};

  pinnedPkgs = import ../pinned.nix;

  patches = [
    ../nix-patches/ghc901-nativebignum.patch
    ../nix-patches/ghc901-fix-order-link-opts.patch
  ];
  
  patchedPkgs = nixpkgs.runCommand "nixos-21.05-2021-07-01-ghc901-nativebignum"
     {
       inherit pinnedPkgs patches;
     }
     ''
       cp -r $pinnedPkgs $out
       chmod -R +w $out
       for patch in $patches; do
         echo "Applying patch $patch";
         patch -d $out -p1 < "$patch";
       done
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
