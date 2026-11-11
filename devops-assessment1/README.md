# DevOps Assessment – Terraform + Database Reliability

This repository implements the DevOps assessment using:

- Terraform for AWS infrastructure design
- AWS VPC, ALB, ECS/Fargate and private RDS PostgreSQL
- Separate `dev` and `prod` Terraform environments
- Docker Compose for a local PostgreSQL database
- SQL migration and seed data
- Query optimization with a composite index
- Timestamped PostgreSQL backup and restore scripts
- GitHub Actions for Terraform formatting, validation and plan

> **Important:** The assessment does not require an actual AWS deployment. Terraform is intended to be reviewed with `terraform fmt`, `terraform init`, `terraform validate`, and `terraform plan -refresh=false`. Database tasks run locally with Docker Compose.

## Repository structure

```text
.
├── .github/
│   └── workflows/
│       └── terraform.yml
├── infra/
│   ├── modules/
│   │   ├── network/
│   │   ├── ecs/
│   │   └── rds/
│   └── envs/
│       ├── dev/
│       └── prod/
├── database/
│   ├── migrations/
│   │   └── 001_init.sql
│   └── seed/
│       └── 001_seed.sql
├── scripts/
│   ├── backup.sh
│   └── restore.sh
├── docker-compose.yml
├── .gitignore
└── README.md
```

## 1. Local database prerequisites

Install:

- Docker Desktop
- Docker Compose

Start PostgreSQL:

```bash
docker compose up -d
```

Check the container:

```bash
docker compose ps
```

The database is exposed locally on:

```text
localhost:5432
```

Database credentials are defined in `docker-compose.yml` for this local assessment only.

## 2. Run database migration

The PostgreSQL container starts with the schema automatically because `database/migrations/001_init.sql` is mounted into `/docker-entrypoint-initdb.d/`.

To recreate the database from scratch:

```bash
docker compose down -v
docker compose up -d
```

Verify the tables:

```bash
docker compose exec postgres psql -U devops -d bookings -c "\dt"
```

Expected tables:

```text
booking_events
hotel_bookings
```

## 3. Load seed data

The seed SQL is also mounted into the PostgreSQL initialization directory, so it runs automatically on a fresh volume.

Verify booking count:

```bash
docker compose exec postgres \
  psql -U devops -d bookings \
  -c "SELECT COUNT(*) FROM hotel_bookings;"
```

Expected result:

```text
100
```

Verify cities and statuses:

```bash
docker compose exec postgres \
  psql -U devops -d bookings \
  -c "SELECT city, status, COUNT(*) FROM hotel_bookings GROUP BY city, status ORDER BY city, status;"
```

## 4. Query optimization

The assessment query is:

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

The solution adds a composite index:

```sql
CREATE INDEX idx_hotel_bookings_city_created_at
ON hotel_bookings (city, created_at);
```

### Why this index?

The query has two selective predicates before aggregation:

- equality filter on `city`
- range filter on `created_at`

The composite index follows that access pattern as `(city, created_at)`. It allows PostgreSQL to narrow the candidate rows before performing the `GROUP BY`.

The query does not filter on `org_id` or `status`, so those columns are not leading index keys.

Run:

```bash
docker compose exec postgres \
  psql -U devops -d bookings \
  -c "EXPLAIN ANALYZE
      SELECT org_id, status, COUNT(*), SUM(amount)
      FROM hotel_bookings
      WHERE city = 'delhi'
        AND created_at >= NOW() - INTERVAL '30 days'
      GROUP BY org_id, status;"
```

With only 100 rows, PostgreSQL may still choose a sequential scan. That is normal because the table is intentionally tiny for the assessment. The important part is that the index matches the production query access pattern.

## 5. Backup

Make scripts executable:

```bash
chmod +x scripts/backup.sh scripts/restore.sh
```

Create a timestamped backup:

```bash
./scripts/backup.sh
```

Backups are written to:

```text
backups/
```

Example:

```text
backups/bookings_20261111_125500.sql.gz
```

The backup uses `pg_dump` from the PostgreSQL Docker container and includes the database schema and data.

## 6. Restore verification

The restore script creates a fresh database named `bookings_restore` and restores the selected backup into it.

Run:

```bash
./scripts/restore.sh backups/<backup-file>.sql.gz
```

Verify the restored database:

```bash
docker compose exec postgres \
  psql -U devops -d bookings_restore \
  -c "SELECT COUNT(*) FROM hotel_bookings;"
```

Expected result:

```text
100
```

Verify booking events:

```bash
docker compose exec postgres \
  psql -U devops -d bookings_restore \
  -c "SELECT COUNT(*) FROM booking_events;"
```

A successful restore should contain the same logical data as the source database.

## 7. Terraform architecture

The Terraform design represents:

```text
Internet
   |
   v
Public ALB
   |
   v
Private ECS/Fargate tasks
   |
   v
Private RDS PostgreSQL
```

### Network

- VPC
- 2 public subnets
- 2 private application subnets
- 2 private database subnets
- Internet Gateway
- NAT Gateway
- Route tables
- Security groups

### Security boundaries

The security groups implement:

```text
Internet -> ALB : 80
ALB -> ECS     : 80
ECS -> RDS     : 5432
Internet -X-> RDS
Internet -X-> ECS
```

RDS is configured as non-public and its security group only permits PostgreSQL traffic from the ECS security group.

## 8. Terraform environments

There are two environments:

```text
infra/envs/dev
infra/envs/prod
```

They have separate:

- variables
- tfvars
- backend configuration
- resource sizing
- RDS backup retention
- deletion protection

### Dev

- smaller Fargate task
- smaller RDS instance
- shorter backup retention
- deletion protection disabled

### Prod

- larger Fargate task
- larger RDS instance
- longer backup retention
- deletion protection enabled

## 9. Terraform commands

Install Terraform 1.6+.

From the repository root:

```bash
cd infra/envs/dev
terraform fmt -recursive
terraform init -backend=false
terraform validate
terraform plan -refresh=false -var-file=dev.tfvars
```

For production:

```bash
cd infra/envs/prod
terraform fmt -recursive
terraform init -backend=false
terraform validate
terraform plan -refresh=false -var-file=prod.tfvars
```

### AWS credentials

For an actual AWS plan, configure credentials using your normal AWS authentication method.

Do not commit:

- AWS access keys
- private keys
- `.tfstate`
- `.tfstate.backup`
- secrets

The `.gitignore` protects these files.

### Backend

The environments contain separate backend configuration examples. The repository deliberately does not contain real AWS account IDs, bucket names or credentials.

For a real deployment, create an S3 state bucket and configure the backend values in the environment-specific backend configuration.

## 10. GitHub Actions

The workflow:

1. Checks out the repository
2. Installs Terraform
3. Runs `terraform fmt -check`
4. Runs `terraform init`
5. Runs `terraform validate`
6. Runs `terraform plan -refresh=false`

The workflow is designed as a review/plan workflow. Actual AWS deployment is intentionally not included because the assessment explicitly says deployment is not required.

For a GitHub Actions plan against AWS, configure an AWS OIDC role and repository permissions in GitHub.

## 11. Validation checklist

### Terraform

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
terraform plan -refresh=false -var-file=dev.tfvars
terraform plan -refresh=false -var-file=prod.tfvars
```

### Database

```bash
docker compose up -d
docker compose ps
./scripts/backup.sh
./scripts/restore.sh backups/<backup-file>.sql.gz
```

### Expected database verification

```sql
SELECT COUNT(*) FROM hotel_bookings;
-- 100

SELECT COUNT(*) FROM booking_events;
-- > 0
```

## 12. GitHub submission

Create a public or company-approved private GitHub repository and push this project.

Before submitting, confirm:

```bash
git status
git add .
git commit -m "Complete DevOps Terraform and database reliability assessment"
git push -u origin main
```

Share the repository URL with the company.

### Do not commit

```text
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
.env
.env.*
backups/
```

## Assessment coverage

| Requirement | Implementation |
|---|---|
| AWS Terraform design | `infra/` |
| VPC/public/private subnets | `infra/modules/network` |
| ALB/ECS/RDS security groups | `infra/modules/*` |
| ECS/Fargate | `infra/modules/ecs` |
| Private RDS | `infra/modules/rds` |
| Dev/Prod environments | `infra/envs/dev`, `infra/envs/prod` |
| Docker Compose DB | `docker-compose.yml` |
| Migration | `database/migrations/001_init.sql` |
| 100 seed bookings | `database/seed/001_seed.sql` |
| Query optimization | composite `(city, created_at)` index |
| Backup | `scripts/backup.sh` |
| Restore | `scripts/restore.sh` |
| GitHub Actions | `.github/workflows/terraform.yml` |
| Documentation | `README.md` |
