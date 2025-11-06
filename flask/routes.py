# routes.py
from flask import Blueprint, request, jsonify, current_app

bp = Blueprint('auth', __name__)

# -------------------- 登录 --------------------
@bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    password = data.get('password')
    username = data.get('username')  # 虽然 Flutter 不用，但保留接口验证

    if not username or not password:
        return jsonify({"error": "用户名或密码不能为空"}), 400

    try:
        conn = current_app.db_conn
        cursor = conn.cursor()
        cursor.execute("SELECT id, password FROM sys_user WHERE username=%s", (username,))
        result = cursor.fetchone()
        cursor.close()

        if not result:
            return jsonify({"error": "用户不存在"}), 401

        user_id, db_password = result

        if db_password != password:
            return jsonify({"error": "用户名或密码错误"}), 401

        return jsonify({"id": user_id})

    except Exception as e:
        print("数据库错误:", e)
        return jsonify({"error": "服务器内部错误"}), 500

# -------------------- 获取部门列表 --------------------
@bp.route('/select_department', methods=['POST'])
def select_department():
    try:
        conn = current_app.db_conn
        cursor = conn.cursor()
        cursor.execute("SELECT id, dept_name FROM sys_department")
        result = cursor.fetchall()
        cursor.close()

        dept_list = [{"id": r[0], "dept_name": r[1]} for r in result]  # ⚠ 返回 dept_name
        return jsonify({"code": 0, "data": dept_list})

    except Exception as e:
        print("select_department 异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

# -------------------- 根据部门名获取团队列表 --------------------
@bp.route('/select_team', methods=['POST'])
def select_team():
    try:
        data = request.get_json() or {}
        dept_name = data.get("department")
        if not dept_name:
            return jsonify({"code": 1, "msg": "缺少部门名"})

        conn = current_app.db_conn
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM sys_department WHERE dept_name=%s", (dept_name,))
        dept = cursor.fetchone()
        if not dept:
            cursor.close()
            return jsonify({"code": 2, "msg": "部门不存在"})

        dept_id = dept[0]
        cursor.execute("SELECT id, team_name FROM sys_team WHERE department_id=%s", (dept_id,))
        teams = cursor.fetchall()
        cursor.close()

        team_list = [{"id": t[0], "team_name": t[1]} for t in teams]  # ⚠ 返回 team_name
        return jsonify({"code": 0, "data": team_list})

    except Exception as e:
        print("select_team 异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

# -------------------- 根据团队名获取员工列表 --------------------
@bp.route('/select_user', methods=['POST'])
def select_user():
    try:
        data = request.get_json() or {}
        team_name = data.get("team")
        if not team_name:
            return jsonify({"code": 1, "msg": "缺少团队名"})

        conn = current_app.db_conn
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM sys_team WHERE team_name=%s", (team_name,))
        team = cursor.fetchone()
        if not team:
            cursor.close()
            return jsonify({"code": 2, "msg": "团队不存在"})

        team_id = team[0]
        cursor.execute("SELECT id, name FROM sys_user WHERE team_id=%s", (team_id,))
        users = cursor.fetchall()
        cursor.close()

        user_list = [{"id": u[0], "username": u[1]} for u in users]  # ⚠ 返回 username
        return jsonify({"code": 0, "data": user_list})

    except Exception as e:
        print("select_user 异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

# -------------------- 根据员工ID获取所属部门、团队和角色ID --------------------
@bp.route('/user_info', methods=['POST'])
def user_info():
    data = request.get_json() or {}
    user_id = data.get("user_id")
    if not user_id:
        return jsonify({"code": 1, "msg": "缺少用户ID"})

    try:
        conn = current_app.db_conn
        cursor = conn.cursor()
        cursor.execute("SELECT name, role_id, team_id FROM sys_user WHERE id=%s", (user_id,))
        user = cursor.fetchone()
        if not user:
            cursor.close()
            return jsonify({"code": 2, "msg": "用户不存在"})

        name, role_id, team_id = user
        role_name = None
        team_name = None
        dept_name = None

        # 获取角色名称
        if role_id:
            cursor.execute("SELECT role_name FROM sys_role WHERE id=%s", (role_id,))
            role = cursor.fetchone()
            role_name = role[0] if role else None

        # 获取团队和部门名称
        if team_id:
            cursor.execute("SELECT team_name, department_id FROM sys_team WHERE id=%s", (team_id,))
            team = cursor.fetchone()
            if team:
                team_name, dept_id = team
                if dept_id:
                    cursor.execute("SELECT dept_name FROM sys_department WHERE id=%s", (dept_id,))
                    dept = cursor.fetchone()
                    dept_name = dept[0] if dept else None

        cursor.close()
        print("user_info 返回:", {
            "username": name,
            "role_id": role_id,
            "role_name": role_name,
            "department": dept_name,
            "team": team_name
        })

        return jsonify({
            "code": 0,
            "data": {
                "username": name,      # ⚠ Flutter 这里用 selectedEmployee
                "role_id": role_id,
                "role_name": role_name,
                "department": dept_name,
                "team": team_name
            }
        })

    except Exception as e:
        print("user_info 异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})
    

# -------------------- 公司十大事项（公司层面主事项） --------------------
@bp.route('/company_top_matters', methods=['GET'])
def company_top_matters():
    try:
        conn = current_app.db_conn
        cursor = conn.cursor()
        # 取公司层面主事项：由角色 1 或 2 创建，且为顶层任务
        cursor.execute(
            """
            SELECT t.id, t.title
            FROM biz_task t
            JOIN sys_user u ON t.creator_id = u.id
            WHERE u.role_id IN (1, 2) AND t.parent_id IS NULL
            ORDER BY t.update_time DESC, t.create_time DESC
            LIMIT 10
            """
        )
        rows = cursor.fetchall()
        cursor.close()
        data = [{"id": r[0], "title": r[1]} for r in rows]
        return jsonify({"code": 0, "data": data})
    except Exception as e:
        print("company_top_matters 异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})


# -------------------- 公司十大派发任务（由高权限派发） --------------------
@bp.route('/company_dispatched_tasks', methods=['GET'])
def company_dispatched_tasks():
    try:
        conn = current_app.db_conn
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT t.id, t.title, t.status, t.progress
            FROM biz_task t
            JOIN sys_user u ON t.creator_id = u.id
            WHERE u.role_id BETWEEN 1 AND 2
            ORDER BY t.update_time DESC, t.create_time DESC
            LIMIT 10
            """
        )
        rows = cursor.fetchall()
        cursor.close()
        data = [
            {"id": r[0], "title": r[1], "status": r[2], "progress": r[3]} for r in rows
        ]
        return jsonify({"code": 0, "data": data})
    except Exception as e:
        print("company_dispatched_tasks 异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})


# -------------------- 个人十大展示项（分配给个人的任务） --------------------
@bp.route('/personal_top_items', methods=['POST'])
def personal_top_items():
    try:
        body = request.get_json() or {}
        user_id = body.get('user_id')
        if not user_id:
            return jsonify({"code": 1, "msg": "缺少用户ID"})

        conn = current_app.db_conn
        cursor = conn.cursor()
        # 个人被分配的任务（assigned_id = user_id）
        cursor.execute(
            """
            SELECT id, title, status, end_time
            FROM biz_task
            WHERE assigned_id = %s
            ORDER BY update_time DESC, create_time DESC
            LIMIT 10
            """,
            (user_id,)
        )
        rows = cursor.fetchall()
        cursor.close()
        data = [
            {"id": r[0], "title": r[1], "status": r[2], "end_time": r[3].strftime('%Y-%m-%d') if r[3] else None}
            for r in rows
        ]
        return jsonify({"code": 0, "data": data})
    except Exception as e:
        print("personal_top_items 异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})


# -------------------- 个人日志（最近10条） --------------------
@bp.route('/personal_logs', methods=['POST'])
def personal_logs():
    try:
        body = request.get_json() or {}
        user_id = body.get('user_id')
        if not user_id:
            return jsonify({"code": 1, "msg": "缺少用户ID"})

        conn = current_app.db_conn
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT wl.id, u.name, wl.content, wl.log_date
            FROM biz_work_log wl
            JOIN sys_user u ON wl.user_id = u.id
            WHERE wl.user_id = %s
            ORDER BY wl.log_date DESC, wl.create_time DESC
            LIMIT 10
            """,
            (user_id,)
        )
        rows = cursor.fetchall()
        cursor.close()
        data = [
            {"id": r[0], "username": r[1], "content": r[2], "date": r[3].strftime('%Y-%m-%d')}
            for r in rows
        ]
        return jsonify({"code": 0, "data": data})
    except Exception as e:
        print("personal_logs 异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})
