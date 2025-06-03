{
  description = "flake for operator mono fonts";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, treefmt-nix }:
    let
      forAllSystems = f:
        nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed
          (system: f nixpkgs.legacyPackages.${system});

      treefmtConfig = forAllSystems (pkgs:
        treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs = {
            nixfmt.enable = true;
            yamlfmt.enable = true;
            ruff-format.enable = true;
            mdformat.enable = true;
          };
          settings.excludes = [
            "*.gitignore"
            "*.lock"
            "*.png"
            "*.pyc"
            "*.txt"
            "LICENSE"
            "Makefile"
            "third_party/*"
          ];
        });

      buildFromSource = { stdenv, lib }:
        stdenv.mkDerivation {
          pname = "operator-mono";
          version = "unstable-2025-06-03";

          src = ./.;

          installPhase = ''
            runHook preInstall
            install -Dm644 fonts/*.ttf -t $out/share/fonts/truetype
            runHook postInstall
          '';
        };
    in
    {
      formatter = forAllSystems (pkgs: treefmtConfig.${pkgs.system}.config.build.wrapper);

      checks = forAllSystems (pkgs: {
        formatting = treefmtConfig.${pkgs.system}.config.build.check self;
      });

      packages = forAllSystems (pkgs: rec {
        operator-mono = pkgs.callPackage buildFromSource {};
        default = operator-mono;
      });
    };
}
