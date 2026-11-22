FROM alpine:3.24

RUN apk add --no-cache openssh-client autossh \
    && addgroup -g 1000 tunnel \
    && adduser -D -u 1000 -G tunnel tunnel

COPY keygen.sh tunnel.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/keygen.sh /usr/local/bin/tunnel.sh

USER 1000:1000
ENTRYPOINT ["/bin/sh", "/usr/local/bin/tunnel.sh"]
