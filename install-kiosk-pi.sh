#!/bin/bash
set -e

echo "=== EZiosk Pi Setup ==="

# Install dependencies
apt update
apt install -y chromium lightdm openbox python3 unclutter

# Remove gnome-keyring — causes login popups on kiosk autologin
apt remove gnome-keyring -y

# Create kiosk user if doesn't exist
id -u kiosk &>/dev/null || useradd -m -s /bin/bash kiosk

# Add to required groups
groupadd -f autologin
groupadd -f nopasswdlogin
usermod -aG autologin,nopasswdlogin kiosk

# Copy kiosk files
mkdir -p /home/kiosk
cp kiosk.html /home/kiosk/
cp server.py /home/kiosk/
cp config.json /home/kiosk/
chown -R kiosk:kiosk /home/kiosk

# LightDM autologin with openbox session
cat > /etc/lightdm/lightdm.conf << 'EOF'
[Seat:*]
autologin-user=kiosk
autologin-user-timeout=0
user-session=openbox
greeter-session=lightdm-gtk-greeter
xsession-wrapper=
EOF

# systemd service for kiosk server
cat > /etc/systemd/system/kiosk.service << 'EOF'
[Unit]
Description=Kiosk Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/kiosk/server.py
Restart=always
User=kiosk

[Install]
WantedBy=multi-user.target
EOF

# Openbox autostart — fires after login
mkdir -p /home/kiosk/.config/openbox
cat > /home/kiosk/.config/openbox/autostart << 'EOF'
unclutter -idle 3 &
chromium --start-fullscreen --no-first-run --disable-pinch --no-restore-state --disable-gpu http://localhost:8080/kiosk.html &
EOF

chown -R kiosk:kiosk /home/kiosk/.config

# Enable and start server
systemctl daemon-reload
systemctl enable --now kiosk

echo ""
echo "=== Done. Reboot to launch. ==="
echo "    sudo reboot"
