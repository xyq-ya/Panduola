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
        conn = current_app.get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, password FROM sys_user WHERE username=%s", (username,))
        result = cursor.fetchone()
        cursor.close()
        conn.close()

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
        conn = current_app.get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, dept_name FROM sys_department")
        result = cursor.fetchall()
        cursor.close()
        conn.close()

        dept_list = [{"id": r[0], "dept_name": r[1]} for r in result]  # ⚠ 返回 dept_name
        return jsonify({"code": 0, "data": dept_list})

    except Exception as e:
        print("select_department 异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

# -------------------- 根据部门名获取团队列表 --------------------
@bp.route('/select_team', methods=['POST'])
def select_team():
    try:
        data = request.get_json(silent=True) or {}
        dept_name = data.get("department")

        conn = current_app.get_db_connection()
        cursor = conn.cursor()

        if dept_name:
            cursor.execute("SELECT id FROM sys_department WHERE dept_name=%s", (dept_name,))
            dept = cursor.fetchone()
            if not dept:
                cursor.close(); conn.close()
                return jsonify({"code": 2, "msg": "部门不存在"})
            cursor.execute("SELECT id, team_name FROM sys_team WHERE department_id=%s", (dept[0],))
        else:
            cursor.execute("SELECT id, team_name FROM sys_team")

        teams = cursor.fetchall()
        cursor.close(); conn.close()
        return jsonify({"code": 0, "data": [{"id": r[0], "team_name": r[1]} for r in teams]})
    except Exception as e:
        print("select_team 异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

# -------------------- 根据团队名获取员工列表 --------------------
@bp.route('/select_user', methods=['POST'])
def select_user():
    try:
        data = request.get_json(silent=True) or {}
        print("select_user recv:", data)
        team_name = data.get("team")

        conn = current_app.get_db_connection()
        cursor = conn.cursor()

        if team_name:
            print("select_user branch=team", team_name)
            cursor.execute("SELECT id FROM sys_team WHERE team_name=%s", (team_name,))
            team = cursor.fetchone()
            if not team:
                cursor.close(); conn.close()
                return jsonify({"code": 2, "msg": "团队不存在"})
            cursor.execute("SELECT id, name FROM sys_user WHERE team_id=%s", (team[0],))
        else:
            print("select_user branch=all")
            cursor.execute("SELECT id, name FROM sys_user")

        users = cursor.fetchall()
        cursor.close(); conn.close()
        return jsonify({"code": 0, "data": [{"id": u[0], "username": u[1]} for u in users]})
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
        conn = current_app.get_db_connection()
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

        cursor.close(); conn.close()
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

# -------------------- 创建任务 --------------------
@bp.route('/create_task', methods=['POST'])
def create_task():
    try:
        data = request.get_json()
        title = data.get('title')
        description = data.get('description', '')
        creator_id = data.get('creator_id')
        assigned_type = data.get('assigned_type', 'personal')  # personal/team/dept
        assigned_id = data.get('assigned_id')
        if not assigned_id:
            assigned_type = 'personal'
            assigned_id = creator_id
        
        start_time = data.get('start_time')
        end_time = data.get('end_time')
        
        # 验证必填字段
        if not title or not creator_id or not start_time or not end_time:
            return jsonify({"code": 1, "msg": "缺少必填字段"})
        
        conn = current_app.get_db_connection()
        cursor = conn.cursor()
        
        # 插入任务
        cursor.execute(
            """INSERT INTO biz_task 
               (title, description, creator_id, assigned_type, assigned_id, start_time, end_time, status, progress)
               VALUES (%s, %s, %s, %s, %s, %s, %s, 'pending', 0)""",
            (title, description, creator_id, assigned_type, assigned_id, start_time, end_time)
        )
        
        task_id = cursor.lastrowid
        conn.commit()
        cursor.close(); conn.close()
        
        print(f"✅ 任务创建成功: id={task_id}, title={title}")
        return jsonify({"code": 0, "msg": "任务创建成功", "data": {"task_id": task_id}})
        
    except Exception as e:
        print("create_task 异常:", e)
        return jsonify({"code": 500, "msg": f"服务器内部错误: {str(e)}"})

# -------------------- 获取任务列表 --------------------
@bp.route('/get_tasks', methods=['POST'])
def get_tasks():
    try:
        data = request.get_json() or {}
        user_id = data.get('user_id')
        
        if not user_id:
            return jsonify({"code": 1, "msg": "缺少用户ID"})
        
        conn = current_app.get_db_connection()
        cursor = conn.cursor()
        
        # 获取用户创建的任务和分配给用户的任务
        cursor.execute("""
            SELECT t.id, t.title, t.description, t.start_time, t.end_time, 
                   t.status, t.progress, t.assigned_type, t.assigned_id,
                   u.name as creator_name
            FROM biz_task t
            LEFT JOIN sys_user u ON t.creator_id = u.id
            WHERE t.creator_id = %s OR t.assigned_id = %s
            ORDER BY t.create_time DESC
            LIMIT 50
        """, (user_id, user_id))
        
        tasks = cursor.fetchall()
        cursor.close()
        conn.close()
        
        task_list = []
        for task in tasks:
            task_list.append({
                "id": task[0],
                "title": task[1],
                "description": task[2],
                "start_time": task[3].strftime('%Y-%m-%d %H:%M:%S') if task[3] else '',
                "end_time": task[4].strftime('%Y-%m-%d %H:%M:%S') if task[4] else '',
                "status": task[5],
                "progress": task[6],
                "assigned_type": task[7],
                "assigned_id": task[8],
                "creator_name": task[9]
            })
        
        return jsonify({"code": 0, "data": task_list})
        
    except Exception as e:
        print("get_tasks 异常:", e)
        return jsonify({"code": 500, "msg": f"服务器内部错误: {str(e)}"})
     