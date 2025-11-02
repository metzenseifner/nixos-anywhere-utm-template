{
  disko.devices = {
    disk.main = {
      device = "/dev/vda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "2048MiB";
            type = "efi";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };

          root = {
            size = "100%";
            type = "linux";
            content = {
              type = "btrfs";
              extraArgs = [ "-L" "nixroot" ];
              subvolumes = {
                # Root filesystem
                "@".mountpoint = "/";
                
                # Home dirs
                "@home".mountpoint = "/home";

                # Nix store (separate for cleanup + snapshot sanity)
                "@nix".mountpoint = "/nix";

                # Snapshots
                "@snapshots".mountpoint = "/.snapshots";
              };
              mountOptions = [
                "compress=zstd"
                "noatime"
              ];
            };
          };
        };
      };
    };
  };
}
