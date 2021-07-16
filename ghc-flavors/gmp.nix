let
  nixpkgs = import <nixpkgs> {};

  pinned = import ../pinned.nix;
  
  pinnedPkgs = import pinned {};

  inherit (pinnedPkgs) pkgs;

  haskellPackages = pkgs.haskell.packages.ghc901;

  ghc901 = pkgs.haskell.compiler.ghc901;
in {
    pkgs = pkgs;
    haskellPackages = haskellPackages;
    ghc901 = ghc901;
}
