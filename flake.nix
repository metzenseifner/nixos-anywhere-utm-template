{
  description = "Portable NixOS anywhere + disko template (ARM/x86 auto)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      systems,
      ...
    }@inputs:
    let
      forEachSystem =
        f:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          f {
            inherit system;
            pkgs = import nixpkgs { inherit system; };
          }
        );

      # helper: default to host if user doesn't pass --system
      mkSystem =
        targetSystem:
        nixpkgs.lib.nixosSystem {
          system = targetSystem;
          modules = [
            disko.nixosModules.disko
            ./disko.nix
            {
              # base system settings
              networking.hostName = "utm-auto";

              boot.loader.systemd-boot.enable = true;
              boot.loader.efi.canTouchEfiVariables = true;

              services.openssh.enable = true;

              users.users.root.openssh.authorizedKeys.keys = [
                # 👉 replace with your key
                "ssh-ed25519 AAAABBBB...yourkey"
              ];

              time.timeZone = "UTC";
              networking.useDHCP = true;

              # bump when upgrading major nixos release
              system.stateVersion = "24.05";
            }
          ];
        };
    in
    {
      # Nix picks the matching host system automatically from builtins.currentSystem. Override with --system x86_64-linux
      # one config entry -- arch auto-detect unless overridden via --system
      #nixosConfigurations.default = mkSystem null;
      # 
      nixosConfigurations = forEachSystem ({ system, ... }: mkSystem system);

      # Enables nix flake init -t github:organization/repo
      # metadata describing how to use this flake as a template, often for tools like nixos-anywhere or disko
      # it’s documentation + hints for users and tools.
      templates = {
        default = {
          path = ./.;
          description = "Portable NixOS anywhere + disko template (ARM/x86)";
          welcomeText = ''
            # NixOS Anywhere + Disko Template

            This template provides portable NixOS configurations for multiple
            architectures using nix-systems/default-linux.

            Next steps:
            1. Edit flake.nix to add your SSH public key
            2. Customize disko.nix for your disk layout
            3. Deploy: nixos-anywhere --flake .#default root@your-host
               Or target specific arch: .#x86_64-linux or .#aarch64-linux
          '';
        };
      };
    };
}
