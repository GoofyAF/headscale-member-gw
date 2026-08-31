# Copy this file to .member-env.nix and fill in YOUR values.
# .member-env.nix is gitignored — it never gets committed.
# `headscaleUrl` and the pre-auth key are tailnet secrets from your admin.
# Do NOT share them in public repos, screenshots, etc.

{
  # ── Your home lab ──────────────────────────────────────────────────────────
  containerIP = "192.168.1.50";  # your LXC's static IP
  lanGateway = "192.168.1.1";    # your home-lab gateway/router
  advertiseRoutes = "192.168.1.0/24";  # subnets to expose to the tailnet

  # ── From your tailnet admin (secure channel) ────────────────────────────────
  headscaleUrl = "https://headscale.example.com";  # the Headscale server URL
  nodeHostname = "home-lab-gw";  # unique name for your node on the tailnet
}