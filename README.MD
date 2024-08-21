# Custom PostgreSQL Backup with Restic

This project provides a Docker image for PostgreSQL database backups using Restic. 

## Features

- Based on the official PostgreSQL Docker image
- Includes Restic for efficient and secure backups
- Flexible: can be used with various scheduling mechanisms (e.g., Kubernetes CronJob)

## Usage

### Pull the image

```bash
docker pull your-docker-hub-username/custom-postgres-backup:latest
```

### Run the container

To perform a backup:

```bash
docker run --rm \
  -e POSTGRES_HOST=your-postgres-host \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_USER=your-postgres-user \
  -e POSTGRES_PASSWORD=your-postgres-password \
  -e RESTIC_PASSWORD=your-restic-password \
  -v /path/to/backups:/backups \
  belov/postgres-restic:latest
```

### Environment Variables

- `POSTGRES_HOST`: PostgreSQL server hostname
- `POSTGRES_PORT`: PostgreSQL server port (default: 5432)
- `POSTGRES_USER`: PostgreSQL username
- `POSTGRES_PASSWORD`: PostgreSQL password
- `POSTGRES_DB`: Specific database to backup (optional, backs up all if not specified)
- `RESTIC_PASSWORD`: Password for Restic repository
- `BACKUP_DIR`: Directory to store backups (default: /backups)
- `CLEANUP_STRATEGY`: Restic forget options for old backups (default: --keep-daily 7 --keep-weekly 4 --keep-monthly 6)

## Building the Image

To build the image locally:

```bash
git clone https://github.com/belov38/postgres-restic.git
cd postgres-restic
docker build -t postgres-restic .
```

## Using with Kubernetes

This image is designed to be used with Kubernetes CronJob. Here's an example CronJob manifest:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
spec:
  schedule: "0 1 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: postgres-backup
            image: belov38/postgres-restic:latest
            env:
              - name: POSTGRES_HOST
                value: "your-postgres-service"
              - name: POSTGRES_USER
                valueFrom:
                  secretKeyRef:
                    name: postgres-secrets
                    key: username
              - name: POSTGRES_PASSWORD
                valueFrom:
                  secretKeyRef:
                    name: postgres-secrets
                    key: password
              - name: RESTIC_PASSWORD
                valueFrom:
                  secretKeyRef:
                    name: restic-secrets
                    key: password
          restartPolicy: OnFailure
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the Apache License - see the [LICENSE](LICENSE) file for details.
