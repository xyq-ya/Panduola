# app.py
from flask import Flask
from flask_cors import CORS
from routes import bp
import config
import pymysql

app = Flask(__name__)
CORS(app)  # 允许 Flutter 跨域

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

# 在 app 上挂载全局连接
app.db_conn = init_db_connection()

# 注册蓝图
app.register_blueprint(bp, url_prefix='/api')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)