{ config, pkgs, lib, ... }:

{
  services.samba = {
    enable = true;
    openFirewall = false; # we'll open only the Tailscale interface
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "NixOS File Server";
        security = "user";
        "map to guest" = "Bad User";
        "guest account" = "nobody";
      };

      black = {
        path = "/mnt/black";
        browseable = "yes";
        writable = "yes";
        "force user" = "lmeireles";
        "guest ok" = "yes";
      };

      r2d2 = {
        path = "/mnt/r2d2";
        browseable = "yes";
        writable = "yes";
        "force user" = "lmeireles";
        "guest ok" = "yes";
      };
    };
  };

  systemd.services.smbd.after = [
    "dislocker-r2d2.service"
    "dislocker-black.service"
  ];

  systemd.services.smbd.requires = [
    "dislocker-r2d2.service"
    "dislocker-black.service"
  ];

  systemd.services.dislocker-r2d2 = {
    description = "Unlock and mount r2d2";

    wantedBy = [ "multi-user.target" ];
    before = [ "smbd.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      EnvironmentFile = "/etc/secrets/bitlocker.env";
    };

    path = with pkgs; [
      dislocker
      util-linux
      coreutils
    ];

    script = ''
      mkdir -p /var/lib/dislocker/r2d2
      mkdir -p /mnt/r2d2

      if ! mountpoint -q /mnt/r2d2; then
        dislocker \
          -V /dev/disk/by-uuid/bff32eec-01f6-4866-b02f-7be551bcfdfb \
          -p"$R2_REC_KEY" \
          -- /var/lib/dislocker/r2d2

        mount -o loop \
          /var/lib/dislocker/r2d2/dislocker-file \
          /mnt/r2d2
      fi
    '';
  };

  systemd.services.dislocker-black = {
    description = "Unlock and mount black";

    wantedBy = [ "multi-user.target" ];
    before = [ "smbd.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      EnvironmentFile = "/etc/secrets/bitlocker.env";
    };

    path = with pkgs; [
      dislocker
      util-linux
      coreutils
    ];

    script = ''
      mkdir -p /var/lib/dislocker/black
      mkdir -p /mnt/black

      if ! mountpoint -q /mnt/black; then
        dislocker \
          -V /dev/disk/by-uuid/1d859527-c9a2-4932-86eb-da72577c2f57 \
          -p"$BLACK_REC_KEY" \
          -- /var/lib/dislocker/black

        mount -o loop \
          /var/lib/dislocker/black/dislocker-file \
          /mnt/black
      fi
    '';
  };

}
