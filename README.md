# macos-brave-docker

Run Brave inside a Linux container on macOS using XQuartz for X11 display forwarding.

**Tested:** Podman on macOS 15.6.1 (MacBook Pro with M1 Pro), XQuartz as the X11 server. Container networking -> `host.containers.internal`.

> Other container runtimes should work similarly, but only Podman is marked as tested here.

---

## Prerequisites

- macOS with a container runtime, for example:
  - Podman (recommended here)
  - Docker Desktop
  - Colima + Docker CLI
- XQuartz (X11 server for macOS)
- Homebrew (for installing XQuartz and optional tools)

---

## Installation

1. **Install XQuartz**
  ```bash
  brew install --cask xquartz
  ```
2. **Enable network client access in XQuartz**
- Open XQuartz
- Preferences -> Security -> enable "Allow connections from network clients"
3. **Enable TCP listening and restart XQuartz**
  ```bash
  defaults write org.xquartz.X11 nolisten_tcp 0
  killall XQuartz 2>/dev/null || true
  open -a XQuartz
  ```
4. **Copy .xinitrc and .Xmodmap files**
  These files auto-configure XQuartz on startup: `.xinitrc` allows localhost X11, sets your keyboard layout, applies `.Xmodmap`, and keeps 
  the session running; `.Xmodmap` resets modifiers and maps both Command keys (Meta_L/Meta_R) to be the only Control keys so ⌘ acts like 
  Ctrl in all X11 clients. If your layout isn’t Turkish, replace `-layout tr` in `.xinitrc` (you can check the current X11 layout with 
  `setxkbmap -query | grep layout`, or use `us`, `gb`, etc.).
  ```bash
  cp .xinitrc .Xmodmap $HOME/
  ```
1. **Open an XQuartz terminal (xterm)**
- With XQuartz running, menu bar -> Applications -> Terminal
- Run the following **inside the XQuartz xterm**:
  -  Generate X11 cookies (recommended)
   ```bash
   xauth generate :0 . trusted 2>/dev/null || true
   xauth list :0
   ```
1. **Build the container image**
  ```bash
  podman build -t brave-docker .
  ```

---

## Run

On macOS, Podman typically reaches the host X server via `host.containers.internal`.
```bash
mkdir -p ./brave-profile

podman run --rm -it \
  --name brave \
  --shm-size=1g \
  -e DISPLAY=host.containers.internal:0 \
  -e XDG_RUNTIME_DIR=/tmp/runtime-brave \
  -v "$HOME/.Xauthority:/home/brave/.Xauthority" \
  -v "$(pwd)/brave-profile:/home/brave/.config/BraveSoftware/Brave-Browser:Z" \
  brave-docker
```

**Notes**
- The image's default command includes `--disable-gpu`. This avoids common GPU issues with XQuartz. You can append extra flags, for example:
  ```bash
  podman run --rm -it \
    --name brave \
    --shm-size=1g \
    -e DISPLAY=host.containers.internal:0 \
    -e XDG_RUNTIME_DIR=/tmp/runtime-brave \
    -v "$HOME/.Xauthority:/home/brave/.Xauthority" \
    -v "$(pwd)/brave-profile:/home/brave/.config/BraveSoftware/Brave-Browser:Z" \
    brave-docker --no-first-run --incognito
  ```

---

## Quick Start (summary)

1) Install and open XQuartz  
2) Enable "Allow connections from network clients"  
3) `defaults write org.xquartz.X11 nolisten_tcp 0` -> restart XQuartz  
4) In XQuartz Applications -> Terminal:
   ```bash
   /opt/X11/bin/xhost +localhost
   xauth generate :0 . trusted 2>/dev/null || true
   ```
5) Build and run the container as shown above

---

## macOS Terminal alternative

You do not have to use the XQuartz xterm. If you prefer macOS Terminal or iTerm:
- Make sure XQuartz is running
- Export a local display before running `xhost`
  ```bash
  export DISPLAY=:0
  /opt/X11/bin/xhost +localhost
  ```
- Then run the container as usual

---

## Troubleshooting

### `xhost: unable to open display ""`
- Run `xhost` inside the XQuartz xterm, or
- In macOS Terminal run `export DISPLAY=:0` first, then `/opt/X11/bin/xhost +localhost`
- Ensure XQuartz is running

### `Error: Can't open display` or `Authorization required, but no authorization protocol specified`
- Confirm XQuartz -> Preferences -> Security -> "Allow connections from network clients" is enabled
- Re-run:
  ```bash
  /opt/X11/bin/xhost +localhost
  xauth generate :0 . trusted 2>/dev/null || true
  xauth list :0
  ```
- Ensure the container sees the cookie:
  - Mount your Xauthority:
    ```bash
    -v "$HOME/.Xauthority:/home/brave/.Xauthority"
    ```
  - Check inside the container:
    ```bash
    echo "$DISPLAY"  # Podman -> host.containers.internal:0, Docker -> host.docker.internal:0
    ```
- As a last resort, you can temporarily relax access (less secure):
  ```bash
  /opt/X11/bin/xhost +
  ```
  Remember to re-enable access control later:
  ```bash
  /opt/X11/bin/xhost -
  /opt/X11/bin/xhost +localhost
  ```

### Brave refuses to start as root with sandbox error
If you see:
```
Running as root without --no-sandbox is not supported
```
then either run as a non-root user (recommended, this image does) or, for testing only, append `--no-sandbox` (not recommended long-term).

### No window appears, but no error
- Verify `DISPLAY` in the container matches your host setting:
  - Podman -> `host.containers.internal:0`
  - Docker Desktop -> `host.docker.internal:0`
- Restart XQuartz:
  ```bash
  killall XQuartz 2>/dev/null || true
  open -a XQuartz
  ```
- Ensure you ran `/opt/X11/bin/xhost +localhost` after XQuartz started

### GPU or rendering glitches
- Keep `--disable-gpu`
- Optional flags:
  ```bash
  --disable-features=UseOzonePlatform --use-gl=swiftshader
  ```

### Optional TCP-to-socket bridge via socat (advanced)
If TCP 6000 connectivity is blocked, bridge TCP to the XQuartz socket:
```bash
brew install socat
SOCK_DIR="$(ls -d /private/tmp/com.apple.launchd.* | head -n 1)"
socat TCP-LISTEN:6000,reuseaddr,fork UNIX-CLIENT:"$SOCK_DIR/org.xquartz:0"
```
Keep this terminal window open while running the container.

---

## Security notes

- Prefer `/opt/X11/bin/xhost +localhost` over `/opt/X11/bin/xhost +`.
- Re-enable access control when done:
  ```bash
  /opt/X11/bin/xhost -
  /opt/X11/bin/xhost +localhost
  ```
- Mounting `~/.Xauthority` is more secure than disabling access control entirely.

---

## About dependencies

The Dockerfile includes common runtime libraries used by Chromium-based browsers (for example `libnss3`, `libxss1`, `libgtk-3-0`, `libx11-6`, and `libasound2t64` on Ubuntu 24.04). If Brave prints a missing library error at runtime, install it by extending the Dockerfile with the required package in `apt-get install`.

---

## Cleanup

Remove the container and local profile data if needed:
```bash
podman rm -f brave 2>/dev/null || true
rm -rf ./brave-profile
```
For a named volume alternative (example with Docker Desktop):
```bash
docker volume create brave_profile
docker run --rm -it \
  -e DISPLAY=host.docker.internal:0 \
  -v brave_profile:/home/brave/.config/BraveSoftware/Brave-Browser \
  brave-docker
# Cleanup later:
docker volume rm brave_profile
```
