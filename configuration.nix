# Headscale member gateway — NixOS LXC
#
# Joins a shared Headscale tailnet and advertises your home-lab subnet.
# Personal laptops/phones stay on their own Tailscale tailnets — untouched.
#
# ── Proxmox LXC requirement (TUN device access) ──────────────────────────────
# Add to /etc/pve/lxc/<vmid>.conf on your Proxmox host:
#   lxc.cgroup2.devices.allow: c 10:200 rwm
#   lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file 0 0
#
# ── Before deploying (see README) ─────────────────────────────────────────────
# 1. cp .member-env.example.nix .member-env.nix  # fill in YOUR values
# 2. Get a pre-auth key from your tailnet admin, and write it into the container:
#      ssh admin@<your-lxc-ip> "sudo mkdir -p /run/secrets && sudo tee /run/secrets/tailscale-authkey"
#
# ── Deploy ────────────────────────────────────────────────────────────────────
#   nixos-rebuild switch \
#     --flake .#headscale-gw \
#     --target-host admin@<your-lxc-ip> \
#     --use-remote-sudo
#
# ── After deploy ──────────────────────────────────────────────────────────────
# Admin approves your subnet route (headscale nodes approve-routes).

{ pkgs, ... }:

let
  # Your private values — imported from gitignored file, never in version control.
  env = import ./.member-env.nix;
in
{
  boot = {
    isContainer = true;
    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
  };

  systemd = {
    suppressedSystemUnits = [
      "dev-mqueue.mount"
      "sys-kernel-debug.mount"
      "sys-fs-fuse-connections.mount"
    ];
    network = {
      enable = true;
      networks."10-eth0" = {
        matchConfig.Name = "eth0";
        networkConfig = {
          Address = "${env.containerIP}/24";
          Gateway = env.lanGateway;
          DNS = [ env.lanGateway ];
        };
      };
    };
  };

  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  networking = {
    hostName = env.nodeHostname;
    useDHCP = false;
    useNetworkd = true;
    useHostResolvConf = false;
    # ── firewall: allow tailnet → LAN forwarding ─────────────────────────────
    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      extraCommands = ''
        iptables -A FORWARD -i tailscale0 -o eth0 -j ACCEPT
        iptables -A FORWARD -i eth0 -o tailscale0 -m state --state ESTABLISHED,RELATED -j ACCEPT
      '';
    };
  };

  services = {
    # ── SSH ───────────────────────────────────────────────────────────────────
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
    # ── tailscale → shared headscale tailnet ─────────────────────────────────
    tailscale = {
      enable = true;
      authKeyFile = "/run/secrets/tailscale-authkey";  # written pre-deploy (README)
      extraUpFlags = [
        "--login-server=${env.headscaleUrl}"
        "--advertise-routes=${env.advertiseRoutes}"
        "--hostname=${env.nodeHostname}"
      ];
    };
  };

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # ADD your own SSH public key:
      # "ssh-ed25519 AAAA... you@yourhost"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # ── nix ───────────────────────────────────────────────────────────────────────
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [ "https://cache.nixos.org" ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  environment.systemPackages = with pkgs; [ vim git curl htop tmux ];

  system = {
    # Required for Proxmox NixOS LXC: keeps /sbin/init pointing to the current
    # generation so reboots don't activate the old template generation.
    activationScripts.sbin-init = {
      text = ''
        ln -sf /nix/var/nix/profiles/system/init /sbin/init
      '';
      deps = [];
    };
    autoUpgrade.enable = false;
    stateVersion = "25.05";
  };
}