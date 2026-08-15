# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./modules/storage.nix
    ];

  # Bootloader.
  # boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Lanzaboote currently replaces the systemd-boot module.
  # This setting is usually set to true in configuration.nix
  # generated at installation time. So we force it to false
  # for now.
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";


  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd"; # necessary so exposing Samba drive doesn't kill connection when TDLS is triggered
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openconnect
  ];

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Keyboard: keep the "US, intl., with dead keys" layout (so ' + e = é),
  # but make it behave like Windows US-International — the acute dead key
  # should only combine with vowels, not consonants. By default the Linux
  # Compose table maps ' + s = ś, ' + m = ḿ, ' + c = ć, etc., which turns
  # "I'm" into "Iḿ" and "let's" into "letś". We override just those
  # consonant combos to emit a literal apostrophe followed by the letter.
  environment.etc."xcompose/dead-acute-latin.compose".text = ''
    # Start from the system default Compose table, then override below.
    include "%L"

    # Neutralise acute + consonant so ' passes through as an apostrophe.
    <dead_acute> <c> : "ç"   ccedilla
    <dead_acute> <C> : "Ç"   Ccedilla
    <dead_acute> <g> : "'g"
    <dead_acute> <G> : "'G"
    <dead_acute> <j> : "'j"
    <dead_acute> <J> : "'J"
    <dead_acute> <k> : "'k"
    <dead_acute> <K> : "'K"
    <dead_acute> <l> : "'l"
    <dead_acute> <L> : "'L"
    <dead_acute> <m> : "'m"
    <dead_acute> <M> : "'M"
    <dead_acute> <n> : "'n"
    <dead_acute> <N> : "'N"
    <dead_acute> <p> : "'p"
    <dead_acute> <P> : "'P"
    <dead_acute> <r> : "'r"
    <dead_acute> <R> : "'R"
    <dead_acute> <s> : "'s"
    <dead_acute> <S> : "'S"
    <dead_acute> <v> : "'v"
    <dead_acute> <V> : "'V"
    <dead_acute> <w> : "'w"
    <dead_acute> <W> : "'W"
    <dead_acute> <z> : "'z"
    <dead_acute> <Z> : "'Z"
  '';

  # Point the input method (IBus) and Xlib at the override table.
  environment.sessionVariables.XCOMPOSEFILE = "/etc/xcompose/dead-acute-latin.compose";

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  
    # NVIDIA
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics.enable = true;

  hardware.nvidia = {
    # Proprietary driver (recommended for most GPUs)
    open = true;

    # Install the nvidia-settings utility
    nvidiaSettings = true;

    # Use the stable driver package
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Optional power management
    powerManagement.enable = true;
  };

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."lmeireles" = {
    isNormalUser = true;
    description = "Lucas Meireles";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.zsh;
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;
  programs.steam.enable = true;
  programs.zsh.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable flakes and the new nix CLI
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.tailscale = {
    enable = true;
  };

  # Start Dropbox automatically on login (graphical session).
  systemd.user.services.dropbox = {
    description = "Dropbox";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.dropbox}/bin/dropbox";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };


  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/shell/keybindings" = {
          show-screenshot-ui = [ "<Super><Shift>s" ];
        };
        # Custom keybinding: Super+E opens the Files app (Nautilus),
        # mirroring the Windows Explorer shortcut.
        "org/gnome/settings-daemon/plugins/media-keys" = {
          custom-keybindings = [
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          ];
        };
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          name = "Open Files";
          command = "nautilus --new-window";
          binding = "<Super>e";
        };
        "org/gnome/desktop/peripherals/keyboard" = {
          repeat = true;
          # ms before a held key starts repeating (default 500)
          delay = lib.gvariant.mkUint32 250;
          # ms between repeats; lower = faster (default 30)
          repeat-interval = lib.gvariant.mkUint32 20;
        };
        # Enable the AppIndicator tray so Dropbox (and similar apps)
        # can show their status/logo icon in the top-right of the top bar.
        "org/gnome/shell" = {
          enabled-extensions = [
            "appindicatorsupport@rgcjonas.gmail.com"
            "dash-to-dock@micxgx.gmail.com"
            "multi-monitors-bar@frederykabryan"
          ];
        };
        # Left-side dock that auto-hides and reveals on hover, showing
        # open windows/apps.
        "org/gnome/shell/extensions/dash-to-dock" = {
          dock-position = "LEFT";
          # dock-fixed = true forces the dock to always stay visible and
          # overrides autohide, so it must be false for auto-hiding to work.
          dock-fixed = false;
          intellihide = false;
          autohide = true;
          # Reveal the dock when the pointer hits the screen edge.
          require-pressure-to-show = true;
          # Show a dot for each open window and the running apps.
          show-running = true;
          show-windows-preview = true;
          # Behave like the top-of-screen activities: keep favorites too.
          show-favorites = true;
        };
        # Add a top bar on the secondary monitor(s), including the clock.
        "org/gnome/shell/extensions/multi-monitors-bar" = {
          show-panel = true;
          show-date-time = true;
          show-activities = true;
          show-app-menu = true;
          show-indicator = true;
        };
      };
    }
  ];

  virtualisation.docker.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #general
  discord
  dislocker
  dropbox
  gnomeExtensions.appindicator
  gnomeExtensions.dash-to-dock
  gnomeExtensions.multi-monitor-bar
  obsidian
  openconnect
  freerdp
  networkmanager-openconnect
  qbittorrent
  vlc
  gnome-screenshot
  proton-vpn
  protontricks

  #secure boot
  sbctl

  #dev
  vscode
  ghostty
  neovim
  tmux
  git
  tree
  ripgrep
  htop
  fzf
  stow
  oh-my-zsh
  opencode
  nodejs
  gcc
  tree-sitter
  jdk25
  rustup
  python3
  unzip
  claude-code
  tcpdump
  docker
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
