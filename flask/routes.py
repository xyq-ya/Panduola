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

        # -------------------- 获取用户日程数据 --------------------
        @bp.route('/get_user_schedule', methods=['POST'])
        def get_user_schedule():
            data = request.get_json() or {}
            user_id = data.get('user_id')

            if not user_id:
                return jsonify({"code": 1, "msg": "缺少用户ID"})

            try:
                conn = current_app.db_conn
                cursor = conn.cursor()

                # 根据用户权限获取不同的数据
                cursor.execute("""
                    SELECT
                        t.id, t.task_name, t.start_date, t.end_date, t.progress,
                        t.priority, t.status, t.color, t.is_milestone,
                        u.name as assignee_name
                    FROM task_schedule t
                    LEFT JOIN sys_user u ON t.assignee_id = u.id
                    WHERE t.assignee_id = %s OR t.created_by = %s
                    ORDER BY t.start_date
                """, (user_id, user_id))

                tasks = cursor.fetchall()
                cursor.close()

                task_list = []
                for task in tasks:
                    task_list.append({
                        "id": task[0],
                        "name": task[1],
                        "start_date": task[2].strftime('%Y-%m-%d') if task[2] else None,
                        "end_date": task[3].strftime('%Y-%m-%d') if task[3] else None,
                        "progress": float(task[4]) if task[4] else 0.0,
                        "priority": task[5],
                        "status": task[6],
                        "color": task[7],
                        "is_milestone": bool(task[8]),
                        "assignee_name": task[9]
                    })

                return jsonify({
                    "code": 0,
                    "data": task_list,
                    "count": len(task_list)
                })

            except Exception as e:
                print("获取日程数据异常:", e)
                return jsonify({"code": 500, "msg": "服务器内部错误"})

# 在 routes.py 中添加
# -------------------- 获取用户任务数据（用于甘特图） --------------------
@bp.route('/get_user_tasks', methods=['POST'])
def get_user_tasks():
    data = request.get_json() or {}
    user_id = data.get('user_id')

    if not user_id:
        return jsonify({"code": 1, "msg": "缺少用户ID"})

    try:
        conn = current_app.db_conn
        cursor = conn.cursor()

        # 获取用户的任务数据（包括分配给用户的任务和用户创建的任务）
        cursor.execute("""
            SELECT
                t.id, t.title, t.description, t.start_time, t.end_time,
                t.progress, t.status, t.creator_id, t.assigned_id,
                u.name as assignee_name,
                creator.name as creator_name
            FROM biz_task t
            LEFT JOIN sys_user u ON t.assigned_id = u.id
            LEFT JOIN sys_user creator ON t.creator_id = creator.id
            WHERE t.assigned_id = %s OR t.creator_id = %s
            ORDER BY t.start_time
        """, (user_id, user_id))

        tasks = cursor.fetchall()
        cursor.close()

        task_list = []
        for task in tasks:
            # 根据任务状态和进度确定颜色
            color = _get_task_color(task[6], task[5])  # status, progress

            task_list.append({
                "id": task[0],
                "name": task[1],
                "description": task[2],
                "start_date": task[3].strftime('%Y-%m-%d') if task[3] else None,
                "end_date": task[4].strftime('%Y-%m-%d') if task[4] else None,
                "progress": float(task[5]) / 100.0 if task[5] is not None else 0.0,  # 转换为0-1的小数
                "status": task[6],
                "creator_id": task[7],
                "assigned_id": task[8],
                "assignee_name": task[9],
                "creator_name": task[10],
                "color": color,
                "is_milestone": False  # 可以根据需要从业务逻辑判断
            })

        return jsonify({
            "code": 0,
            "data": task_list,
            "count": len(task_list)
        })

    except Exception as e:
        print("获取任务数据异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

def _get_task_color(status, progress):
    """根据任务状态和进度确定颜色"""
    if status == 'completed':
        return '#4CAF50'  # 绿色 - 已完成
    elif status == 'in_progress':
        if progress >= 80:
            return '#2196F3'  # 蓝色 - 接近完成
        elif progress >= 50:
            return '#FF9800'  # 橙色 - 进行中
        else:
            return '#FFC107'  # 黄色 - 刚开始
    else:  # pending
        return '#9E9E9E'  # 灰色 - 未开始