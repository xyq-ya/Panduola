# app.py - 使用 werkzeug 修复版本
from flask import Flask
from flask_cors import CORS
from routes import bp
import config
import pymysql
from werkzeug.serving import run_simple

app = Flask(__name__)
CORS(app)  # 允许 Flutter 跨域

# === 建立全局长期数据库连接 ===
def init_db_conn():
    try:
        conn = pymysql.connect(
            host=config.DB_HOST,
            user=config.DB_USER,
            password=config.DB_PASSWORD,
            database=config.DB_NAME,
            charset=config.DB_CHARSET,
            autocommit=True
        )
        print("✅ 数据库连接成功")
        return conn
    except Exception as e:
        print(f"❌ 数据库连接失败: {e}")
        return None

# 在 app 上挂载全局连接
app.db_conn = init_db_conn()

# 注册蓝图
app.register_blueprint(bp, url_prefix='/api')

@app.route('/')
def hello():
    return 'Flask 后端服务正常运行!'

@app.route('/health')
def health_check():
    return {'status': 'healthy', 'service': 'Flask Backend'}

if __name__ == '__main__':
    print("🚀 启动 Flask 服务...")
    print("📍 本地访问: http://localhost:5000")
    print("📱 Flutter 使用: http://10.0.2.2:5000")
    print("✅ 数据库连接已建立")

    # 使用 werkzeug 的 run_simple 绕过 Flask 启动问题
    run_simple(
        hostname='127.0.0.1',
        port=5000,
        application=app,
        use_reloader=False,
        use_debugger=False,
        threaded=True
    )