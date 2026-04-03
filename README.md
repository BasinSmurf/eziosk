# EZiosk

Dead-simple touch/click kiosk launcher. Windows 8-style tile grid.
Configured via JSON. Password-protected admin panel.

---

## Files

```
kiosk/
  kiosk.html      ← the whole app
  config.json     ← all your settings (edit here or via admin panel)
  server.py       ← tiny Python server (serves files + saves config)
  README.md
```

---

## Quick Start

```bash
cd kiosk
python3 server.py
```

Then open: `http://localhost:8080/kiosk.html`

Default admin password: **admin** — change it immediately via the ⚙ button.

---

## Config Reference

```json
{
  "title": "My Kiosk",          // header text (second half gets accent color)
  "columns": 3,                 // null = auto-fit based on button count
  "accent": "#e05a00",          // accent color (hex)
  "password_hash": "...",       // SHA-256 of your admin password
  "buttons": [
    {
      "label": "Sign In",       // big tile text (required)
      "icon": "📋",             // optional emoji icon above label
      "sub": "daily check-in",  // optional small subtext
      "color": "#1c1c1c",       // tile background color (hex)
      "url": "https://..."      // where to go on click
    }
  ]
}
```

### URL tips

- **Google Drive file**: `https://drive.google.com/file/d/FILE_ID/view`
- **Google Form**: `https://docs.google.com/forms/d/FORM_ID/viewform`
- **Pre-filled form**: use Google's pre-fill link builder, paste the full URI
- **Any public URL**: just paste it

---

## Running in Kiosk Mode (Chromium / Linux)

```bash
# Start the server in background
python3 /opt/kiosk/server.py &

# Launch Chromium in kiosk mode
chromium-browser \
  --kiosk \
  --no-first-run \
  --disable-pinch \
  --overscroll-history-navigation=0 \
  --disable-context-menu \
  "http://localhost:8080/kiosk.html"
```

### Auto-start on boot (systemd)

`/etc/systemd/system/kiosk.service`:

```ini
[Unit]
Description=Kiosk
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/kiosk/server.py 8080
Restart=always
User=kiosk

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable kiosk
sudo systemctl start kiosk
```

A separate display service (e.g. a `@reboot` crontab entry or second systemd unit)
handles launching Chromium after login.

---

## Changing the Admin Password

Option A: Admin panel (⚙ → enter current password → change password field → Save)

Option B: CLI

```python
python3 -c "import hashlib; print(hashlib.sha256(b'yourpassword').hexdigest())"
```

Paste the output into `config.json` as `password_hash`.

---

## Running Without the Server

Open `kiosk.html` directly in a browser (`file://`). It will load `config.json`
if served, otherwise fall back to defaults. Config changes in the admin panel
will apply in-memory but won't persist to disk (no server = no POST endpoint).
Fine for testing; use the server for production.
