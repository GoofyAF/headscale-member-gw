# This file is tracked in the repo WITH PLACEHOLDER VALUES so the flake can
# evaluate. Edit it in place with YOUR values in your own clone/fork — do NOT
# push real values (IPs, headscale URL) back to the upstream repo.
# `headscaleUrl` and the pre-auth key are tailnet secrets from your admin.
# Do NOT share them in public repos, screenshots, etc.
{
  # ── Your home lab (edit these) ─────────────────────────────────────────────
  containerIP = "192.168.1.50";  # your LXC's static IP
  lanGateway = "192.168.1.1";    # your home-lab gateway/router
  advertiseRoutes = "192.168.1.0/24";  # subnets to expose to the tailnet

  # ── From your tailnet admin (secure channel) ────────────────────────────────
  headscaleUrl = "https://headscale.example.com";  # the Headscale server URL
  nodeHostname = "home-lab-gw";  # unique name for your node on the tailnet
}