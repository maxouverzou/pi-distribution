{
  description = "Pi coding agent distribution with Nix builders for Agent Skills";

  # Flake inputs
  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1"; # unstable Nixpkgs

  # Flake outputs
  outputs =
    { self, ... }@inputs:

    let
      # The systems supported for this flake
      supportedSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];

      # Helper to provide system-specific attributes
      forEachSupportedSystem =
        f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ];
            };
          }
        );
    in
    {
      # Custom packages
      packages = forEachSupportedSystem (
        { pkgs }:
        {
          inherit (pkgs) hello pi-coding-agent skills-ref;
          inherit (pkgs.piExtensions)
            tools
            plan-mode
            sandbox
            limits
            ;
          inherit (pkgs.piSkills.conductor)
            conductor-setup
            conductor-implement
            conductor-new-track
            conductor-status
            conductor-revert
            ;
          inherit (pkgs.piSkills.browser) browser-tools;
          inherit (pkgs.piPrompts) git-commit;
          default = pkgs.pi-coding-agent;
        }
      );

      # Custom overlays
      overlays.default = import ./overlays/default.nix;

      # Library functions (system-independent, but need pkgs for implementation)
      # Users should use the overlay which adds these to pkgs
      lib = forEachSupportedSystem ({ pkgs }: pkgs.piLib);

      # Home Manager modules
      homeManagerModules.default = import ./modules/home-manager/default.nix;

      devShells = forEachSupportedSystem (
        { pkgs }:
        let
          # Fetch @types/node from npm
          typesNode = pkgs.stdenv.mkDerivation {
            pname = "types-node";
            version = "22.10.5";

            src = pkgs.fetchurl {
              url = "https://registry.npmjs.org/@types/node/-/node-22.10.5.tgz";
              hash = "sha256-8eZtwsBA+FPy6d69XZGqkOyIHvXyni31HWasLzrWf0Y=";
            };

            dontBuild = true;

            installPhase = ''
              mkdir -p $out/lib/node_modules/@types/node
              cp -r . $out/lib/node_modules/@types/node/
            '';
          };
        in
        {
          default = pkgs.mkShellNoCC {
            # The Nix packages provided in the environment
            packages = with pkgs; [
              pi-coding-agent

              nodejs
              typescript
              typesNode
            ];

            shellHook = ''
              mkdir -p .nix
              ln -sfn ${pkgs.pi-coding-agent} .nix/pi-coding-agent
              ln -sfn ${typesNode} .nix/types-node
            '';
          };
        }
      );
    };
}
