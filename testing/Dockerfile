FROM debian:buster-slim

ARG TARGETARCH 
ARG TARGETPLATFORM
RUN echo "Target Platform : $TARGETPLATFORM"
RUN echo "Target Arch : $TARGETARCH"

# Install basic required packages.
RUN set -x \
 && apt-get update \
 && apt-get upgrade -y \
 && apt-get dist-upgrade -y \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        dumb-init \
        xmlstarlet \
        jq \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ADD getplexdeb.sh /tmp
RUN chmod a+x /tmp/getplexdeb.sh ; /tmp/getplexdeb.sh ; ls -la /tmp/*deb
