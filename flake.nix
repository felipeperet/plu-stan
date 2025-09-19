{
  description = "plu-stan - Haskell Static Analysis for Plutus/Plinth";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowBroken = true;
          allowUnfree = true;
        };
      };

      # System dependencies needed for Cardano/Plutus
      systemDependencies = with pkgs; [
        # Crypto libraries (using blst instead of libblst)
        blst
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

          # Configure pkg-config paths for crypto libraries
          export PKG_CONFIG_PATH="${pkgs.blst}/lib/pkgconfig:${pkgs.libsodium}/lib/pkgconfig:${pkgs.secp256k1}/lib/pkgconfig:$PKG_CONFIG_PATH"
        '';
      };
    in {
      devShells.default = devShell;
      packages.default = pkgs.haskell.packages.ghc98.callCabal2nix "stan" ./. {};
    });
}
