FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# System deps + X11 + runtime libs + DBus
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg \
    fonts-liberation libasound2t64 \
    libnss3 libxss1 libatk-bridge2.0-0 libgtk-3-0 libx11-6 \
    x11-apps dbus dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

# Brave repo + install
RUN install -d -m 0755 /etc/apt/keyrings && \
    curl -fsSLo /etc/apt/keyrings/brave-browser-archive-keyring.gpg \
      https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
      > /etc/apt/sources.list.d/brave-browser-release.list && \
    apt-get update && apt-get install -y --no-install-recommends brave-browser && \
    rm -rf /var/lib/apt/lists/*

# Entry script to start a DBus session and launch Brave
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

# Non-root user
ARG USERNAME=brave
RUN useradd -m -s /bin/bash ${USERNAME}

# Switch to user and prepare home
USER ${USERNAME}
ENV HOME=/home/${USERNAME}
WORKDIR /home/${USERNAME}

# Brave profile dir
RUN mkdir -p "${HOME}/.config/BraveSoftware/Brave-Browser"

# Keep runtime dir stable to avoid warnings
ENV XDG_RUNTIME_DIR=/tmp/runtime-brave

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--disable-gpu","--disable-dev-shm-usage","--no-first-run","--password-store=basic","--disable-notifications"]