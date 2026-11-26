FROM alpine:3.20.0
USER 65534:65534
HEALTHCHECK --interval=30s CMD test -r /etc/alpine-release || exit 1
