#!/usr/bin/env python
"""
Execute mysql/init.sql using credentials from flask/config.py (or environment variables it uses).
Run: python .\scripts\create_db.py
"""
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
CONFIG_PATH = os.path.join(ROOT, 'flask', 'config.py')
SQL_PATH = os.path.join(ROOT, 'mysql', 'init.sql')

if not os.path.exists(CONFIG_PATH):
    print('Could not find', CONFIG_PATH)
    sys.exit(1)

ns = {}
with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
    code = f.read()
exec(code, ns)

DB_HOST = ns.get('DB_HOST', os.getenv('DB_HOST', 'localhost'))
DB_USER = ns.get('DB_USER', os.getenv('DB_USER', 'root'))
DB_PASSWORD = ns.get('DB_PASSWORD', os.getenv('DB_PASSWORD', ''))
DB_NAME = ns.get('DB_NAME', os.getenv('DB_NAME', 'task_management_system'))
DB_CHARSET = ns.get('DB_CHARSET', os.getenv('DB_CHARSET', 'utf8mb4'))

print(f'Using DB host={DB_HOST} user={DB_USER} db={DB_NAME}')

if not os.path.exists(SQL_PATH):
    print('SQL file not found:', SQL_PATH)
    sys.exit(1)

with open(SQL_PATH, 'r', encoding='utf-8') as f:
    sql = f.read()

try:
    import pymysql
    conn = pymysql.connect(host=DB_HOST, user=DB_USER, password=DB_PASSWORD, charset=DB_CHARSET, autocommit=True)
    cursor = conn.cursor()
    statements = [s.strip() for s in sql.split(';') if s.strip()]
    for i, stmt in enumerate(statements, 1):
        try:
            cursor.execute(stmt)
        except Exception as e:
            print(f'Error executing statement #{i}:', e)
    cursor.close()
    conn.close()
    print('SQL execution finished.')
except Exception as e:
    print('Failed to connect or execute SQL:', e)
    sys.exit(2)
