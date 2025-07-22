# syntax=docker/dockerfile:1

FROM gabemendoza1/cloudcode-baseimage-ubuntu-fips:jammy-22.04

# set version labels
ARG BUILD_DATE
ARG VERSION
ARG MODS_VERSION="v3"
ARG PKG_INST_VERSION="v1"
ARG LSIOWN_VERSION="v1"
ARG S6_OVERLAY_VERSION="3.1.6.2"
ARG S6_OVERLAY_ARCH="x86_64"

LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="civisanalytics"

# add s6 overlay
RUN \
  echo "**** add s6 overlay ****" && \
  curl -o /tmp/s6-overlay-noarch.tar.xz -L \
    "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" && \
  tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
  curl -o /tmp/s6-overlay-arch.tar.xz -L \
    "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz" && \
  tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz && \
  curl -o /tmp/s6-overlay-symlinks-noarch.tar.xz -L \
    "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz" && \
  tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz && \
  curl -o /tmp/s6-overlay-symlinks-arch.tar.xz -L \
    "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz" && \
  tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz && \
  rm -rf /tmp/s6-overlay*.tar.xz

# add LinuxServer.io mod scripts
RUN \
  echo "**** add LinuxServer.io mod scripts ****" && \
  curl -o /docker-mods -L \
    "https://raw.githubusercontent.com/linuxserver/docker-mods/mod-scripts/docker-mods.${MODS_VERSION}" && \
  chmod +x /docker-mods && \
  mkdir -p /etc/s6-overlay/s6-rc.d/init-mods-package-install && \
  curl -o /etc/s6-overlay/s6-rc.d/init-mods-package-install/run -L \
    "https://raw.githubusercontent.com/linuxserver/docker-mods/mod-scripts/package-install.${PKG_INST_VERSION}" && \
  chmod +x /etc/s6-overlay/s6-rc.d/init-mods-package-install/run && \
  curl -o /usr/bin/lsiown -L \
    "https://raw.githubusercontent.com/linuxserver/docker-mods/mod-scripts/lsiown.${LSIOWN_VERSION}" && \
  chmod +x /usr/bin/lsiown

# set environment variables
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/root" \
  LANGUAGE="en_US.UTF-8" \
  LANG="en_US.UTF-8" \
  TERM="xterm" \
  S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0" \
  S6_VERBOSITY=1 \
  S6_STAGE2_HOOK=/docker-mods \
  VIRTUAL_ENV=/lsiopy \
  PATH="/lsiopy/bin:$PATH"

RUN \
  echo "**** setup LinuxServer.io environment ****" && \
  echo "**** create abc user and folders (if not exists) ****" && \
  if ! id abc >/dev/null 2>&1; then \
    useradd -u 911 -U -d /config -s /bin/false abc && \
    usermod -G users abc; \
  fi && \
  mkdir -p \
    /app \
    /config \
    /defaults \
    /lsiopy && \
  echo "**** cleanup ****" && \
  apt-get autoremove -y && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /var/log/*

# add local files
COPY root/ /

ENTRYPOINT ["/init"]
