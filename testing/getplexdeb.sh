#!/bin/bash

case $TARGETARCH in
  "amd64")
    ARCHPLX="linux-x86_64"
    ;;
  "arm64")
    ARCHPLX="linux-aarch64"
    ;;
  "arm")
    ARCHPLX="linux-armv7neon"
    ;;
  *)
    ARCHPLX="linux-x86_64"
    ;;
esac

PLEXDEBURL=$(curl -s "https://plex.tv/pms/downloads/5.json" -o - |jq -r ".computer.Linux.releases[] | select(.distro==\"debian\" and .build==\"${ARCHPLX}\").url" )

echo "Fetching : $PLEXDEBURL to /tmp/plexmediaserver.deb"
curl "$PLEXDEBURL" -o /tmp/plexmediaserver.deb