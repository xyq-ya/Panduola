#!/usr/bin/env python
import os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
CONFIG_PATH = os.path.join(ROOT, 'flask', 'config.py')

ns = {}
with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
    code = f.read()
exec(code, ns)

DB_HOST = ns.get('DB_HOST', os.getenv('DB_HOST', 'localhost'))
DB_USER = ns.get('DB_USER', os.getenv('DB_USER', 'root'))
DB_PASSWORD = ns.get('DB_PASSWORD', os.getenv('DB_PASSWORD', 'Goi@7330'))
DB_CHARSET = ns.get('DB_CHARSET', os.getenv('DB_CHARSET', 'utf8mb4'))

print('Testing DB connection with:')
print(' host=', DB_HOST)
print(' user=', DB_USER)
print(' password= <hidden>')

try:
    import pymysql
    conn = pymysql.connect(host=DB_HOST, user=DB_USER, password=DB_PASSWORD, charset=DB_CHARSET, connect_timeout=5)
    print('Connection succeeded')
    conn.close()
except Exception as e:
    print('Connection failed:')
    import traceback
    traceback.print_exc()
    sys.exit(1)
