{
  description = "Portable ARM/x86 NixOS btrfs + Snapper base";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    # optional: include sops if you use secrets later
    # sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, disko, ... } @ inputs:
  let
    # Pick right system at deploy time
    forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
  in {
    nixosConfigurations = forAllSystems (system: nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        disko.nixosModules.disko

        ./hardware-configuration.nix
        ./disko.nix  # ← your btrfs layout w/ boot=2GiB, swap, subvols

        ({ config, pkgs, ... }: {
          networking.hostName = "portable-btrfs-box";

          # SSH access for nixos-anywhere install
          users.users.root.openssh.authorizedKeys.keys = [
            # put public key, NOT private. not a secret.
            "ssh-ed25519 AAAA...yourpubkey... user@host"
          ];

          # === BTRFS + Snapper ===
          boot.supportedFilesystems = [ "btrfs" ];
          boot.btrfs.enable = true; # rollback boot support

          services.snapper = {
            snapshotRootOnBoot = true;
            configs = {
              root.subvolume = "/";
              home.subvolume = "/home";
            };
          };

          # Auto snapshots
          systemd.timers.snapper-timeline.enable = true;
          systemd.timers.snapper-cleanup.enable = true;

          # Useful tools
          environment.systemPackages = with pkgs; [
            btrfs-progs
            snapper
            # btrfs-assistant # optional GUI if a laptop later
          ];

          # UEFI assumed (UTM)
          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;

          # Timezone & locale just to be comfy
          time.timeZone = "Europe/Vienna";
          i18n.defaultLocale = "en_US.UTF-8";
        })
      ];
    });
  };
}
