#!/bin/sh
set -e

JOB_ID="job-$(tr -dc 'a-f0-9' < /dev/urandom | head -c 8)"
DB_LIST=$(psql -Atq -c 'SELECT datname FROM pg_catalog.pg_database;' | grep -v '^\(postgres\|template.*\)$')
DB_LIST=$(echo "$DB_LIST" | sort -R)  # shuffle list

echo "Job ID: $JOB_ID"
echo "Target repo: $REPO_PATH"
echo "Cleanup strategy: $CLEANUP_STRATEGY"
echo "Start backup for:"
echo "$DB_LIST"
echo

echo "Backup started at $(date +%Y-%m-%d\ %H:%M:%S)"
for db in $DB_LIST; do
  (
  REPO_DIR="$REPO_PATH/$db"
  mkdir -p "$REPO_DIR"
  restic -r "$REPO_DIR" cat config >/dev/null 2>&1 || \
    restic -r "$REPO_DIR" init --repository-version 2
  restic -r "$REPO_DIR" unlock --remove-all >/dev/null 2>&1 || true
  pg_dump -Z0 -Ft -d "$db" | \
    restic -r "$REPO_DIR" backup --tag "$JOB_ID" --stdin --stdin-filename dump.tar

  if [ $? -eq 0 ]; then
    restic -r "$REPO_DIR" tag --tag "$JOB_ID" --set "completed"
  else
    echo "Error: Backup failed for database $db"
    exit 1
  fi
  )
  if [ $? -ne 0 ]; then
    echo "Error: Backup process failed for database $db"
    exit 1
  fi
done
echo "Backup finished at $(date +%Y-%m-%d\ %H:%M:%S)"

echo "Run cleanup:"
echo "Cleanup started at $(date +%Y-%m-%d\ %H:%M:%S)"
for db in $DB_LIST; do
  (
    set -x
    REPO_DIR="$REPO_PATH/$db"
    restic forget -r "$REPO_DIR" --group-by=tags --keep-tag "completed"
    restic forget -r "$REPO_DIR" --group-by=tags $CLEANUP_STRATEGY
    restic prune -r "$REPO_DIR"
  )
  if [ $? -ne 0 ]; then
    echo "Error: Cleanup process failed for database $db"
    exit 1
  fi
done
echo "Cleanup finished at $(date +%Y-%m-%d\ %H:%M:%S)"
