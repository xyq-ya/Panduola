# app.py
from flask import Flask
from flask_cors import CORS
from routes import bp
import config
import pymysql
import os


app = Flask(__name__)
CORS(app)  # 允许 Flutter 跨域

# 将后端配置注入到 app.config，方便各个模块统一读取（优先使用 config.py，再回退到环境变量）
app.config['ARK_API_KEY'] = getattr(config, 'ARK_API_KEY', None)
app.config['ARK_BASE_URL'] = getattr(config, 'ARK_BASE_URL', None)
app.config['AI_API_URL'] = getattr(config, 'AI_API_URL', None) or os.getenv('AI_API_URL')
app.config['AI_API_KEY'] = getattr(config, 'AI_API_KEY', None) or os.getenv('AI_API_KEY')

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


# 注册蓝图
app.register_blueprint(bp, url_prefix='/api')


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
