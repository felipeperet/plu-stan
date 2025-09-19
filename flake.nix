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

      # Use GHC 9.6
      haskellPackages = pkgs.haskell.packages.ghc96.override {
        overrides = final: prev: {
        };
      };

      # System dependencies needed for Cardano/Plutus
      systemDependencies = with pkgs; [
        # Crypto libraries
        blst
        libsodium
        secp256k1
        # Build tools
        pkg-config
        zlib
        # Development tools
        cabal-install
        (haskellPackages.ghc)
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
      packages.default = haskellPackages.callCabal2nix "stan" ./. {};
    });
}
