# app.py
from flask import Flask
from flask_cors import CORS
from routes import bp
import config
import pymysql
import os

app = Flask(__name__)
CORS(app)

app.config['ARK_API_KEY'] = getattr(config, 'ARK_API_KEY', None)
app.config['ARK_BASE_URL'] = getattr(config, 'ARK_BASE_URL', None)
app.config['AI_API_URL'] = getattr(config, 'AI_API_URL', None) or os.getenv('AI_API_URL')
app.config['AI_API_KEY'] = getattr(config, 'AI_API_KEY', None) or os.getenv('AI_API_KEY')

# 不再创建全局连接，改为在需要时创建
def create_db_connection():
    """创建新的数据库连接"""
    try:
        conn = pymysql.connect(
            host=config.DB_HOST,
            user=config.DB_USER,
            password=config.DB_PASSWORD,
            database=config.DB_NAME,
            charset=config.DB_CHARSET,
            autocommit=True
        )
        return conn
    except Exception as e:
        print(f"创建数据库连接失败: {e}")
        return None

# 将连接创建函数挂载到 app 上
app.create_db_connection = create_db_connection

# 注册蓝图
app.register_blueprint(bp, url_prefix='/api')

if __name__ == '__main__':
    app.run(host='::', port=5000, debug=True)