# install one command
curl -fsSL https://tailscale.com/install.sh | sh

# Add Tailscale’s package signing key and repository:
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list

# Install Tailscale
sudo apt-get update
sudo apt-get install tailscale

# Connect your machine to your Tailscale network and authenticate in your browser:
sudo tailscale up

# You’re connected! You can find your Tailscale IPv4 address by running:
tailscale ip -4
