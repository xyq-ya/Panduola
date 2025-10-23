# app.py
from flask import Flask
from flask_cors import CORS
from routes import bp
import config
import pymysql
import os

app = Flask(__name__)
CORS(app)  # 允许 Flutter 跨域

# 支持 mock 模式以便在没有 MySQL 时也能本地运行客户端（设置环境变量 MOCK_BACKEND=1）
USE_MOCK = os.getenv('MOCK_BACKEND', '0') == '1'
app.config['MOCK_DB'] = USE_MOCK


# === 建立全局长期数据库连接 ===
def init_db_connection():
    conn = pymysql.connect(
        host=config.DB_HOST,
        user=config.DB_USER,
        password=config.DB_PASSWORD,
        database=config.DB_NAME,
        charset=config.DB_CHARSET,
        autocommit=True
    )
    return conn


# 在 app 上挂载全局连接（除非启用了 mock 模式）
if not USE_MOCK:
    try:
        app.db_conn = init_db_connection()
        print('DB connection established')
    except Exception as e:
        # 连接失败时打印错误并继续；若需要严格失败可以改为 raise
        print('无法建立数据库连接，启用 mock? 环境变量 MOCK_BACKEND=1 可跳过 DB: ', e)
        app.db_conn = None
else:
    print('启动在 MOCK 后端模式（MOCK_BACKEND=1）——不会连接 MySQL')


# 注册蓝图
app.register_blueprint(bp, url_prefix='/api')


if __name__ == '__main__':
    # Flask debug 模式下自动重载会重新读取环境变量——这在开发时通常是期望的
    app.run(host='0.0.0.0', port=5000, debug=True)