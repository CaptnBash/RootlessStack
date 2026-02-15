FROM alpine:latest

RUN apk update && \
    apk add --no-cache \
    openssh-client \
    borgbackup \
    mariadb-client && \
    rm -rf /var/cache/apk/*

COPY borg-backup.sh /

ENTRYPOINT ["/bin/sh", "/borg-backup.sh"]
