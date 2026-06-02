#!/bin/sh
set -e
echo "Starting init_db (if DATABASE_URL provided)"
python init_db.py || true
echo "Launching uvicorn"
exec uvicorn main:app --host 0.0.0.0 --port 8000
