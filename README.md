## GHC 9.0.1 with native bignum

> A new bignum library, ghc-bignum, improving portability and allowing GHC to
be more easily used with integer libraries other than GMP.
https://www.haskell.org/ghc/blog/20210204-ghc-9.0.1-released.html

Building the GHC 9.0.1 (native bignum enabled) and pushing its binary to
cachix

## Why?

I want to build some static binaries without linking the GMP (LGPL).

## Problems

Well, I made a small patch in the nixpkgs allowing me to use a GHC 9.0.1 with
`BIGNUM_BACKEND=native`. But, when I tried to compile my project, I had the
following error:

```
/nix/store/qvc6cz5d43jhhm4a3r48xkrc82xh1s95-binutils-2.35.1/bin/ld.gold: error: /nix/store/zkjz3a1hn4r015l2421xh73823h29hig-glibc-2.32-46-static/lib/libpthread.a(lowlevellock.o): multiple definition of '__lll_lock_wait_private'
/nix/store/qvc6cz5d43jhhm4a3r48xkrc82xh1s95-binutils-2.35.1/bin/ld.gold: /nix/store/zkjz3a1hn4r015l2421xh73823h29hig-glibc-2.32-46-static/lib/libc.a(libc-lowlevellock.o): previous definition here
collect2: error: ld returned 1 exit status
```

I searched about this error and I found this issue in the GHC Project:
https://gitlab.haskell.org/ghc/ghc/-/issues/19029

The problem: the GHC is generating a compilation command with flags in wrong
order, the flag `-lc` must be before `-lpthread`.

So, I cloned the ghc repository to understand how theses flags are generated,
then I made a patch to fix the order of the flags:

```diff
diff --git a/compiler/GHC/Unit/State.hs b/compiler/GHC/Unit/State.hs
index 2efd962..072c853 100644
--- a/compiler/GHC/Unit/State.hs
+++ b/compiler/GHC/Unit/State.hs
@@ -1814,11 +1814,24 @@ getUnitLinkOpts :: DynFlags -> [UnitId] -> IO ([String], [String], [String])
 getUnitLinkOpts dflags pkgs =
   collectLinkOpts dflags `fmap` getPreloadUnitsAnd dflags pkgs

+-- | The order of '-lc' and '-lpthread' when building a
+-- static binary must be '-lpthread' before '-lc' ('-lpthread -lc')
+-- See https://gitlab.haskell.org/ghc/ghc/-/issues/19029
+-- This function ensures '-lrt -lpthread' as the first flags
+-- The '-lrt' is dependency of '-lpthread'
+fixOrderLinkOpts :: [String] -> [String]
+fixOrderLinkOpts opts
+  | pthread `elem` opts = rt:pthread:filter (`notElem` [rt,pthread]) opts
+  | otherwise = opts
+  where
+    rt = "-lrt"
+    pthread = "-lpthread"
+
 collectLinkOpts :: DynFlags -> [UnitInfo] -> ([String], [String], [String])
 collectLinkOpts dflags ps =
     (
         concatMap (map ("-l" ++) . packageHsLibs dflags) ps,
-        concatMap (map ("-l" ++) . unitExtDepLibsSys) ps,
+        fixOrderLinkOpts $ concatMap (map ("-l" ++) . unitExtDepLibsSys) ps,
         concatMap unitLinkerOptions ps
     )
 collectArchives :: DynFlags -> UnitInfo -> IO [FilePath]
```

I tried to use this fix with only the '-lpthread' at the head of the list, but I got a
compilation error about the 'librt', and then I found this:
https://stackoverflow.com/questions/58848694/gcc-whole-archive-recipe-for-static-linking-to-pthread-stopped-working-in-rec

So, I added the '-lrt' before '-lpthread' and the static binary build worked. 

Also, the GHC 9.0.1 with gmp enabled has the same problem with the '-lc -lpthread'.

#### Results

Flags before:
```
-lHSbase-4.15.0.0 -lHSghc-bignum-1.0 -lHSghc-prim-0.7.0 -lHSrts -lc -lm -lm -lrt -ldl -lffi -lpthread -static
```

Flags after (with the patch):

```
-lHSbase-4.15.0.0 -lHSghc-bignum-1.0 -lHSghc-prim-0.7.0 -lHSrts -lrt -lpthread -lc -lm -lm -ldl -lffi -static
```


#### Testing the patch

1. You must have [Nix](https://nixos.org/download.html) installed

2. Clone this repo

3. Use the following cache (to avoid a huge compilation time)

    [Install cachix](https://docs.cachix.org/installation.html)

    ```bash
    $ cachix use ghc9-native-bignum
    ```

4. Run
    ```bash
    $ nix-build static.nix -A nativeBignumWithPatch
    ```

There are 3 flavors that you can try:

- `gmp`: GHC 9.0.1 with bignum backend gmp
- `nativeBignum`: GHC 9.0.1 with bignum backend native
- `nativeBignumWithPatch`: the same of `nativeBignum` but with the patch 

## Usage

To avoid a huge compilation time, you can use the following cache:

```bash
$ cachix use ghc9-native-bignum
```

[Instructions to install the cachix](https://docs.cachix.org/installation.html)

### `genStatic.nativeBignumWithPatch`

It will try to generate a static binary using the GHC 9.0.1 (native bignum enabled)

```nix
let
  repo = builtins.fetchTarball {
    name = "nix-ghc901-native-bignum";
    url = "https://github.com/jeovazero/nix-ghc901-native-bignum/archive/cd691a8965cfe531335a53bb0b8140eae2ebe825.tar.gz";
    sha256 = "1apa4fsczz6hx91sms5zmsv89qdcdvmjsjn424ijad3gib30ynib";
  };

  inherit (import repo) genStatic;

  # `src` is the location of the cabal project
  app = { name = "app"; src = ./.; };
in
  genStatic.nativeBignumWithPatch { app = app; }
```


### `statify`

There is a use case in this [repo](https://github.com/jeovazero/janitor/blob/main/build/static.nix#L4)

```nix
let
  repo = builtins.fetchTarball {
    name = "nix-ghc901-native-bignum";
    url = "https://github.com/jeovazero/nix-ghc901-native-bignum/archive/cd691a8965cfe531335a53bb0b8140eae2ebe825.tar.gz";
    sha256 = "1apa4fsczz6hx91sms5zmsv89qdcdvmjsjn424ijad3gib30ynib";
  };

  inherit (import repo) statify flavors;
  inherit (flavors.nativeBignumWithPatch) haskellPackages pkgs;

  myHSPkgs = haskellPackages.override {
    overrides = self: super: { 
      memory = self.callHackage "memory" "0.16.0" {};
      cryptonite = self.callHackage "cryptonite" "0.29" {};
    };
  };

  app = { name = "janitor"; src = ../.; };
in
  statify { haskellPackages = myHSPkgs; pkgs = pkgs;}  { app = app; }
```
