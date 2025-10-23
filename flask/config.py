# config.py
# Prefer environment variables for local/CI configuration. Defaults provided for
# quick local development but DO NOT use these credentials in production.
import os

DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_USER = os.getenv('DB_USER', 'root')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'Goi@7330')  # change locally or use env var
DB_NAME = os.getenv('DB_NAME', 'task_management_system')
DB_CHARSET = os.getenv('DB_CHARSET', 'utf8mb4')

# Optional: allow switching to sqlite or mock via env var in future if desired