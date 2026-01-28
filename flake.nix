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
          inherit (pkgs.piExtensions) tools plan-mode sandbox;
          inherit (pkgs.piSkills.conductor)
            conductor-setup
            conductor-implement
            conductor-new-track
            conductor-status
            conductor-revert
            ;
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
        {
          default = pkgs.mkShellNoCC {
            # The Nix packages provided in the environment
            packages = with pkgs; [
              node2nix
              nodejs
              skills-ref
            ];

            # Set any environment variables for your dev shell
            env = { };

            # Add any shell logic you want executed any time the environment is activated
            shellHook = ''
              echo "Pi distribution dev shell"
              echo "Available: node2nix, nodejs, skills-ref"
            '';
          };
        }
      );
    };
}
