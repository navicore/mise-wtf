#!/usr/bin/env bash
set -euo pipefail

# Quick script to connect to postgres

echo "Connecting to PostgreSQL..."
kubectl run psql --rm -it --image=postgres:15-alpine --restart=Never -- \
    psql postgresql://apiuser:localdevpassword@postgres:5432/observations