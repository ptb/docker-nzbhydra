FROM alpine:3.3
# MAINTAINER Peter T Bosse II <ptb@ioutime.com>

RUN \
  REQUIRED_APKS="python" \
  && BUILD_APKS="ca-certificates openssl wget" \

  && USERID_ON_HOST=502 \

  && adduser -D -G users -g NZBHydra -s /sbin/nologin -u $USERID_ON_HOST nzbhydra \

  && apk add --update-cache \
    $REQUIRED_APKS \
    $BUILD_APKS \

  && mkdir -p /app/ \
  && wget \
    --output-document - \
    --quiet \
    https://github.com/theotherp/nzbhydra/archive/master.tar.gz \
    | tar -xz -C /app/ \
  && chown -R nzbhydra:users /app/nzbhydra-master/ \

  && wget \
    --output-document - \
    --quiet \
    https://api.github.com/repos/just-containers/s6-overlay/releases/latest \
    | sed -n "s/^.*browser_download_url.*: \"\(.*s6-overlay-amd64.tar.gz\)\".*/\1/p" \
    | wget \
      --input-file - \
      --output-document - \
      --quiet \
    | tar xz -C / \

  && mkdir -p /etc/services.d/nzbhydra/ \
  && printf "%s\n" \
    "#!/usr/bin/env sh" \
    "set -ex" \
    "exec s6-applyuidgid -g 100 -u $USERID_ON_HOST \\" \
    "  /usr/bin/python /app/nzbhydra-master/nzbhydra.py \\" \
    "    --config /home/nzbhydra/settings.cfg \\" \
    "    --database /home/nzbhydra/nzbhydra.db \\" \
    "    --nobrowser" \
    > /etc/services.d/nzbhydra/run \
  && chmod +x /etc/services.d/nzbhydra/run \

  && apk del \
    $BUILD_PACKAGES \
  && rm -rf /tmp/* /var/cache/apk/* /var/tmp/*

ENTRYPOINT ["/init"]
EXPOSE 5075

# docker build --rm --tag ptb2/nzbhydra .
# docker run --detach --name nzbhydra --net host \
#   --publish 5075:5075/tcp \
#   --volume ~/nzbhydra:/home/nzbhydra \
#   ptb2/nzbhydra
