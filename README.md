## GHC 9.0.1 with native bignum

> A new bignum library, ghc-bignum, improving portability and allowing GHC to be more easily used with integer libraries other than GMP.
https://www.haskell.org/ghc/blog/20210204-ghc-9.0.1-released.html


Building the GHC 9.0.1 (with native bignum) and pushing its binary to cachix

## Why?

I want to build some static binaries without linking the GMP(LGPL).


## Example

```nix
let
  nixpkgs = import <nixpkgs> {};
  inherit (nixpkgs) pkgs;

  patchedRepo = builtins.fetchGit {
    "url" = "git@github.com:jeovazero/nix-ghc901-native-bignum.git";
    "rev" = "1520983a9fc99cc4cb177f6dfd998e7b3276561c";
  };

  patchedNix = import "${patchedRepo}/default.nix" {};

  app = patchedNix.haskellPackages.callCabal2nix "app" ./app {};
in
  pkgs.haskell.lib.overrideCabal app (drv: {
    enableSharedExecutables = false;
    enableSharedLibraries = false;
    configureFlags = [
      "--ghc-option=-optl=-static"
      "--extra-lib-dirs=${pkgs.zlib.static}/lib"
      "--extra-lib-dirs=${pkgs.libffi.overrideAttrs (old: { dontDisableStatic = true; })}/lib"
      "--disable-executable-stripping"
      "--disable-executable-dynamic"
      "--disable-library-profiling"
    ];
  })
```
