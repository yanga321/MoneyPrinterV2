#!/usr/bin/env bash
# AWS EC2 Setup Script for MoneyPrinterV2
# Tested on: Ubuntu 24.04 LTS (t3.medium or larger recommended)
#
# Usage:
#   1. Launch an EC2 instance (Ubuntu 24.04, t3.medium+, 30GB+ EBS)
#   2. SSH in: ssh -i your-key.pem ubuntu@<public-ip>
#   3. Clone the repo: git clone https://github.com/yanga321/MoneyPrinterV2.git
#   4. Run this script: bash MoneyPrinterV2/scripts/setup_aws.sh
#   5. Connect via VNC to set up Firefox profiles
#   6. Then run: cd MoneyPrinterV2 && source venv/bin/activate && python src/main.py

set -euo pipefail

echo "========================================="
echo " MoneyPrinterV2 — AWS EC2 Setup"
echo "========================================="

# --- System packages ---
echo "[1/7] Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
    python3.12 python3.12-venv python3-pip \
    firefox \
    imagemagick \
    ffmpeg \
    curl wget ca-certificates \
    fontconfig fonts-liberation \
    libsndfile1 \
    zstd \
    git

# --- Desktop environment + VNC (for Firefox profile setup) ---
echo "[2/7] Installing lightweight desktop + VNC server..."
sudo apt-get install -y --no-install-recommends \
    xfce4 xfce4-goodies \
    tigervnc-standalone-server tigervnc-common \
    dbus-x11

# Configure VNC for the current user
mkdir -p ~/.vnc
echo "[2/7] Set a VNC password (you'll need this to connect):"
vncpasswd

cat > ~/.vnc/xstartup << 'XSTARTUP'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
XSTARTUP
chmod +x ~/.vnc/xstartup

# --- Ollama ---
echo "[3/7] Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# Start Ollama and pull default model
sudo systemctl enable ollama
sudo systemctl start ollama
sleep 3
echo "[3/7] Pulling llama3.2:3b model (this takes a few minutes)..."
ollama pull llama3.2:3b

# --- Project setup ---
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "[4/7] Setting up project in $REPO_DIR..."
cd "$REPO_DIR"

python3.12 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# --- Config ---
echo "[5/7] Creating config.json..."
if [ ! -f config.json ]; then
    cp config.example.json config.json

    # Auto-detect ImageMagick path
    MAGICK_PATH=$(which convert 2>/dev/null || echo "/usr/bin/convert")
    sed -i "s|\"imagemagick_path\": \"\"|\"imagemagick_path\": \"$MAGICK_PATH\"|" config.json

    # Set Ollama model
    sed -i 's|"ollama_model": ""|"ollama_model": "llama3.2:3b"|' config.json

    echo "    -> config.json created. You'll need to add API keys manually."
else
    echo "    -> config.json already exists, skipping."
fi

# --- Firewall note ---
echo "[6/7] Firewall reminder..."
echo "    To connect via VNC, add an inbound rule to your EC2 security group:"
echo "    - Port 5901, TCP, from your IP only"
echo "    Or use SSH tunneling (recommended, no security group change needed):"
echo "      ssh -L 5901:localhost:5901 -i your-key.pem ubuntu@<public-ip>"

# --- Systemd service (optional, for 24/7 scheduling) ---
echo "[7/7] Creating systemd service for headless scheduling..."
sudo tee /etc/systemd/system/mpv2-scheduler.service > /dev/null << SYSTEMD
[Unit]
Description=MoneyPrinterV2 Scheduler
After=network.target ollama.service

[Service]
Type=simple
User=$USER
WorkingDir=$REPO_DIR
ExecStart=$REPO_DIR/venv/bin/python src/cron.py
Restart=on-failure
RestartSec=10
Environment=PATH=$REPO_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=multi-user.target
SYSTEMD

echo ""
echo "========================================="
echo " Setup Complete!"
echo "========================================="
echo ""
echo " Next steps:"
echo ""
echo " 1. START VNC SERVER:"
echo "    vncserver :1 -geometry 1280x800 -depth 24"
echo ""
echo " 2. CONNECT FROM YOUR MACHINE:"
echo "    ssh -L 5901:localhost:5901 -i your-key.pem ubuntu@<public-ip>"
echo "    Then open a VNC client (TigerVNC, RealVNC) -> localhost:5901"
echo ""
echo " 3. IN THE VNC DESKTOP:"
echo "    - Open Firefox and log into YouTube, Twitter, etc."
echo "    - Note the Firefox profile path:"
echo "      ls ~/.mozilla/firefox/*.default*"
echo "    - Edit config.json and set \"firefox_profile\" to that path"
echo ""
echo " 4. RUN THE APP:"
echo "    cd $REPO_DIR"
echo "    source venv/bin/activate"
echo "    python src/main.py"
echo ""
echo " 5. FOR 24/7 SCHEDULING (after config is done):"
echo "    sudo systemctl enable mpv2-scheduler"
echo "    sudo systemctl start mpv2-scheduler"
echo ""
echo " 6. ADD YOUR API KEYS to config.json:"
echo "    - nanobanana2_api_key: Get from https://aistudio.google.com/apikey"
echo "    - assembly_ai_api_key: (optional) from https://www.assemblyai.com"
echo ""
