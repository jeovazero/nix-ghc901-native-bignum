## GHC 9.0.1 with native bignum

> A new bignum library, ghc-bignum, improving portability and allowing GHC to
be more easily used with integer libraries other than GMP.
https://www.haskell.org/ghc/blog/20210204-ghc-9.0.1-released.html

Building the GHC 9.0.1 (native bignum enabled) and pushing its binary to
cachix

## Why?

I want to build some static binaries without linking the GMP (LGPL).

## Problems

Well, I did a small patch in the nixpkgs allowing me to use a GHC 9.0.1 with
`BIGNUM_BACKEND=native`. But, when I tried to compile my project I had the
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
then I did a patch to fix the order of the flags:

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

I tried to use this fix with only the '-lpthread' at the head of the list, but a had a
compilation error about the 'librt', and I found this:
https://stackoverflow.com/questions/58848694/gcc-whole-archive-recipe-for-static-linking-to-pthread-stopped-working-in-rec

So, I added the '-lrt' before '-lpthread' and the static binary build worked. 

Also, the GHC 9.0.1 with gmp enabled have the same problem with '-lc -lpthread'.

## Results

Flags before:
```
-lHSbase-4.15.0.0 -lHSghc-bignum-1.0 -lHSghc-prim-0.7.0 -lHSrts -lc -lm -lm -lrt -ldl -lffi -lpthread -static
```

Flags after (with my patch):

```
-lHSbase-4.15.0.0 -lHSghc-bignum-1.0 -lHSghc-prim-0.7.0 -lHSrts -lrt -lpthread -lc -lm -lm -ldl -lffi -static
```


## Testing my patch

1. You must have [Nix](https://nixos.org/download.html) installed

2. Clone this repo

3. Use the following cache (to avoid a huge compilation time)

    [Install cachix](https://docs.cachix.org/installation.html)

    ```bash
    $ cachix use ghc9-native-bignum
    ```

4. Run
    ```bash
    $ nix-build static.nix -A 'nativeWithPatch'
    ```

There are 3 flavors:

- `gmp`: GHC 9.0.1 with bignum backend gmp
- `native`: GHC 9.0.1 with bignum backend native
- `nativeWithPatch`: the same of `native` but with my patch 

