# routes.py
from flask import Blueprint, request, jsonify, current_app

bp = Blueprint('auth', __name__)

@bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({"error": "用户名或密码不能为空"}), 400

    try:
        conn = current_app.db_conn

        cursor = conn.cursor()

        sql = "SELECT id, password FROM sys_user WHERE username=%s"
        cursor.execute(sql, (username,))
        result = cursor.fetchone()  # fetchone 返回单条记录，格式是 tuple

        cursor.close()

        if not result:
            return jsonify({"error": "用户不存在"}), 401

        user_id, db_password = result

        if db_password != password:
            return jsonify({"error": "用户名或密码错误"}), 401

        print(f"接收用户名: {username}, 输入密码: {password}")
        print(f"数据库密码: {db_password}, 用户ID: {user_id}")
        return jsonify({"id": user_id})

    except Exception as e:
        print("数据库错误:", e)
        return jsonify({"error": "服务器内部错误"}), 500