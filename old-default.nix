let
  nixpkgs = import <nixpkgs> {};

  pinnedPkgs = builtins.fetchTarball {
    name = "nixos-21.05-2021-07-01";
    url = "https://github.com/nixos/nixpkgs/archive/21b696caf392ad6fa513caf3327d0aa0430ffb72.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`",
    sha256 = "1056r3383aaf5zhf7rbvka76gqxb8b7rwqxnmar29vxhs9h56m5k";
  };

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
