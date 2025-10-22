# run_server.py
from waitress import serve
from app import app

if __name__ == '__main__':
    print("启动 Waitress 服务器在 http://localhost:5000")
    serve(app, host='0.0.0.0', port=5000)  # 改为 5000