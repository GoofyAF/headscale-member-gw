# headscale-member-gw

A NixOS LXC template that joins a shared [Headscale](https://github.com/juanfont/headscale)
tailnet and advertises your home-lab subnet to the other members of that tailnet.

This template is **infrastructure-only**: your personal laptops/phones stay on their
own Tailscale tailnets, untouched. The gateway on your Proxmox host is a small
dedicated LXC that connects your home lab to the shared tailnet.

## What it does

- Runs a minimal NixOS container on your Proxmox host
- Connects to the shared Headscale tailnet via a pre-auth key (not stored in this repo)
- Advertises your home-lab subnet(s) so other tailnet members can reach them

## Requirements

- A Proxmox host where you can create LXC containers
- [Nix](https://nixos.org) installed on the machine you deploy from (or a pre-built
  NixOS runner)
- A **pre-auth key** for the tailnet — your tailnet admin gives you this separately

## Setup

### 1. Create the LXC on Proxmox

Clone a NixOS LXC base (or create a new container) and give it a static IP in your
home lab, e.g. `192.168.1.50/24`, gateway `192.168.1.1`.

Add these lines to `/etc/pve/lxc/<vmid>.conf` **(required for the TUN device)**:

```
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file 0 0
```

### 2. Fill in your values

Copy `.member-env.example.nix` to `.member-env.nix` and set:

| Variable          | What it is                                             |
|-------------------|--------------------------------------------------------|
| `containerIP`     | Your LXC's static IP (e.g. `192.168.1.50`)            |
| `lanGateway`      | Your home-lab gateway (e.g. `192.168.1.1`)            |
| `advertiseRoutes` | The subnet(s) you want to expose (e.g. `192.168.1.0/24`) |
| `headscaleUrl`    | The tailnet's Headscale server URL — **from your admin** |
| `nodeHostname`    | A unique name for your node on the tailnet            |

`.member-env.nix` is gitignored — it never leaves your machine.

> **Security:** `headscaleUrl` and the pre-auth key are per-tailnet secrets. Do not
> commit them anywhere. Keep `.member-env.nix` out of version control (already handled).

### 3. Write the pre-auth key into the container

Get a pre-auth key from your admin, then write it into the container before first boot:

```bash
ssh admin@<your-lxc-ip> "sudo mkdir -p /run/secrets && sudo tee /run/secrets/tailscale-authkey"
# paste the key, Ctrl-D
```

### 4. Deploy

```bash
nix develop  # if you don't have nixos-rebuild for flakes
nixos-rebuild switch \
  --flake .#headscale-gw \
  --target-host admin@<your-lxc-ip> \
  --use-remote-sudo
```

### 5. Admin approves your route

Your admin enables your advertised subnet route on the Headscale server:

```
headscale nodes list-routes
headscale nodes approve-routes -i <node-id> -r <your-subnet>
```

## What to change (if anything)

- `system.stateVersion` — leave at the default unless you know what you're doing
- `time.timeZone` — set to your local zone if you want logs in local time
- Add `openssh.authorizedKeys.keys` for your own SSH key(s) in `configuration.nix`

## Layout

```
configuration.nix       # the gateway NixOS config (imports .member-env.nix)
.member-env.example.nix # template for YOUR values (gitignored when copied)
flake.nix               # nix flake definition
flake.lock              # pinned inputs
```

## FAQ / Troubleshooting

- **`tailscale` shows "Your login is invalid"** — the pre-auth key wasn't written to
  `/run/secrets/tailscale-authkey` before `tailscale up`, or it expired. Regenerate
  with your admin and rewrite it.
- **Route shows as available but not approved** — admin hasn't approved it yet.
- **No internet from inside the gateway** — the LXC needs outbound access from your
  home-lab subnet; the config only *forwards* tailscale traffic to your LAN.