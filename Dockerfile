FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# sys deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg \
    fonts-liberation libasound2t64 \
    x11-apps \
    && rm -rf /var/lib/apt/lists/*

# Brave repo + installation
RUN install -d -m 0755 /etc/apt/keyrings && \
    curl -fsSLo /etc/apt/keyrings/brave-browser-archive-keyring.gpg \
      https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
      > /etc/apt/sources.list.d/brave-browser-release.list && \
    apt-get update && apt-get install -y --no-install-recommends brave-browser && \
    rm -rf /var/lib/apt/lists/*

ARG USERNAME=brave
RUN useradd -m -s /bin/bash ${USERNAME}

USER ${USERNAME}
ENV HOME=/home/${USERNAME}
WORKDIR /home/${USERNAME}
RUN mkdir -p "${HOME}/.config/BraveSoftware/Brave-Browser"

ENTRYPOINT ["brave-browser"]
CMD ["--disable-gpu"]
