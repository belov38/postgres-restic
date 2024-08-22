FROM postgres:16

RUN apt-get update && apt-get install -y \
    restic \
    s3cmd \
    python3-pip \
    && pip3 install --upgrade awscli \
    && rm -rf /var/lib/apt/lists/*

ENV POSTGRES_DB="**None**" \
    POSTGRES_HOST="**None**" \
    POSTGRES_PORT=5432 \
    POSTGRES_USER="**None**" \
    POSTGRES_PASSWORD="**None**" \
    BACKUP_DIR="/backups" \
    RESTIC_REPOSITORY="/backups" \
    RESTIC_PASSWORD="**None**" \
    CLEANUP_STRATEGY="--keep-daily 7 --keep-weekly 4 --keep-monthly 6"

COPY backup-local.sh /backup-local.sh
RUN chmod +x /backup-local.sh

RUN mkdir -p /backups && chmod 777 /backups

ENTRYPOINT ["/bin/bash"]

CMD ["/backup-local.sh"]
