{
  description = "plu-stan - Haskell Static Analysis for Plutus/Plinth";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Cardano Haskell Packages for Plutus dependencies
    CHaP = {
      url = "github:intersectmbo/cardano-haskell-packages?ref=repo";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    CHaP,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowBroken = true;
          allowUnfree = true;
        };
      };

      haskellPackages = pkgs.haskell.packages.ghc98.override {
        overrides = final: prev: {
        };
      };

      # System dependencies needed for Cardano/Plutus
      systemDependencies = with pkgs; [
        # Crypto libraries
        libblst
        libsodium
        secp256k1

        # Build tools
        pkg-config
        zlib

        # Development tools
        cabal-install
        ghc
        haskell-language-server

        # Optional tools
        hlint
        fourmolu
      ];

      devShell = pkgs.mkShell {
        buildInputs =
          systemDependencies
          ++ [
            pkgs.git
            pkgs.curl
            pkgs.wget
          ];

        shellHook = ''
          echo "• plu-stan development environment"
          echo "• Project: $(basename $PWD)"
          echo "• GHC version: $(ghc --version)"
          echo "• Cabal version: $(cabal --version | head -1)"
          echo ""
          echo "• Quick start:"
          echo "    cabal update"
          echo "    cabal build"
          echo "    cabal run stan -- --help"

          export PKG_CONFIG_PATH="${pkgs.libblst}/lib/pkgconfig:${pkgs.libsodium}/lib/pkgconfig:${pkgs.secp256k1}/lib/pkgconfig:$PKG_CONFIG_PATH"
        '';
      };
    in {
      devShells.default = devShell;

      devShell = devShell;

      packages.default = haskellPackages.callCabal2nix "stan" ./. {};
    });
}
