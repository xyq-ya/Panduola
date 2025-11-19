# routes.py
from flask import Blueprint, request, jsonify, current_app
from flask import Blueprint, request, jsonify, current_app
from decimal import Decimal
import json

bp = Blueprint('auth', __name__)

class DecimalEncoder(json.JSONEncoder):
    """自定义 JSON 编码器处理 Decimal 类型"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

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

        # 1. 获取用户所在的团队ID
        cursor.execute("SELECT team_id FROM sys_user WHERE id=%s", (user_id,))
        user_info = cursor.fetchone()

        if not user_info:
            cursor.close()
            return jsonify({"code": 2, "msg": "用户信息不存在"})

        user_team_id = user_info[0]

        print(f"🔍 调试信息: user_id={user_id}, user_team_id={user_team_id}")
        print(f"🔍 查询条件: assigned_id={user_team_id} OR creator_id={user_id}")

        # 2. 先测试简单的查询，确保能查到数据
        cursor.execute("SELECT COUNT(*) FROM biz_task WHERE assigned_id = %s", (user_team_id,))
        assigned_count = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(*) FROM biz_task WHERE creator_id = %s", (user_id,))
        creator_count = cursor.fetchone()[0]

        print(f"🔍 分配给团队 {user_team_id} 的任务数: {assigned_count}")
        print(f"🔍 用户 {user_id} 创建的任务数: {creator_count}")

        # 3. 执行主查询
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
        """, (user_team_id, user_id))

        tasks = cursor.fetchall()

        print(f"🔍 查询结果: 找到 {len(tasks)} 个任务")
        for task in tasks:
            print(f"📋 任务: id={task[0]}, title='{task[1]}', assigned_id={task[8]}, creator_id={task[7]}")

        cursor.close()

        task_list = []
        for task in tasks:
            color = _get_task_color(task[6], task[5])

            # 判断任务类型
            task_type = "个人任务" if task[7] == user_id else "团队任务"

            task_list.append({
                "id": task[0],
                "name": task[1],
                "description": task[2],
                "start_date": task[3].strftime('%Y-%m-%d') if task[3] else None,
                "end_date": task[4].strftime('%Y-%m-%d') if task[4] else None,
                "progress": float(task[5]) / 100.0 if task[5] is not None else 0.0,
                "status": task[6],
                "creator_id": task[7],
                "assigned_id": task[8],
                "assignee_name": task[9],
                "creator_name": task[10],
                "color": color,
                "is_milestone": False,
                "task_type": task_type
            })

        return jsonify({
            "code": 0,
            "data": task_list,
            "count": len(task_list),
            "debug_info": {
                "user_id": user_id,
                "user_team_id": user_team_id,
                "assigned_task_count": assigned_count,
                "created_task_count": creator_count,
                "final_task_count": len(task_list)
            }
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

# -------------------- 获取团队成员信息 --------------------
@bp.route('/get_team_members', methods=['POST'])
def get_team_members():
    data = request.get_json() or {}
    team_id = data.get('team_id')
    current_user_id = data.get('current_user_id')

    if not team_id:
        return jsonify({"code": 1, "msg": "团队ID不能为空"})

    try:
        conn = current_app.db_conn
        cursor = conn.cursor()

        # 查询团队成员信息
        cursor.execute("""
            SELECT u.id, u.username, u.name, u.email, u.mobile, r.role_name
            FROM sys_user u
            LEFT JOIN sys_role r ON u.role_id = r.id
            WHERE u.team_id = %s
            ORDER BY
                CASE r.role_name
                    WHEN '部门老总' THEN 1
                    WHEN '管理员' THEN 2
                    WHEN '部门经理' THEN 3
                    WHEN '团队队长' THEN 4
                    ELSE 5
                END,
                u.id
        """, (team_id,))

        members = cursor.fetchall()
        cursor.close()

        members_data = []
        for member in members:
            members_data.append({
                "id": member[0],
                "username": member[1],
                "name": member[2],
                "email": member[3],
                "mobile": member[4],
                "role_name": member[5]
            })

        print(f"获取团队成员: team_id={team_id}, 成员数量={len(members_data)}")
        return jsonify({
            "code": 0,
            "data": members_data
        })

    except Exception as e:
        print("获取团队成员异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

# -------------------- 获取用户任务统计数据 --------------------
@bp.route('/get_user_stats', methods=['POST'])
def get_user_stats():
    data = request.get_json() or {}
    user_id = data.get('user_id')

    if not user_id:
        return jsonify({"code": 1, "msg": "用户ID不能为空"})

    try:
        conn = current_app.db_conn
        cursor = conn.cursor()

        print(f"🔍 开始统计用户 {user_id} 的任务数据")

        # 1. 首先验证用户是否存在
        cursor.execute("SELECT id, team_id FROM sys_user WHERE id=%s", (user_id,))
        user_info = cursor.fetchone()

        if not user_info:
            cursor.close()
            print(f"❌ 用户 {user_id} 不存在")
            return jsonify({"code": 2, "msg": "用户信息不存在"})

        user_team_id = user_info[1]
        print(f"✅ 用户存在: user_id={user_id}, team_id={user_team_id}")

        # 2. 分别查询各种状态的任务数量（使用简单查询避免复杂逻辑）
        # 总任务数：用户创建的任务 + 分配给用户团队的任务
        cursor.execute("""
            SELECT COUNT(*)
            FROM biz_task
            WHERE assigned_id = %s OR creator_id = %s
        """, (user_team_id, user_id))
        total_tasks_result = cursor.fetchone()
        total_tasks = int(total_tasks_result[0]) if total_tasks_result and total_tasks_result[0] is not None else 0

        # 已完成任务数 (progress = 100)
        cursor.execute("""
            SELECT COUNT(*)
            FROM biz_task
            WHERE (assigned_id = %s OR creator_id = %s) AND progress = 100
        """, (user_team_id, user_id))
        completed_tasks_result = cursor.fetchone()
        completed_tasks = int(completed_tasks_result[0]) if completed_tasks_result and completed_tasks_result[0] is not None else 0

        # 进行中任务数 (0 < progress < 100)
        cursor.execute("""
            SELECT COUNT(*)
            FROM biz_task
            WHERE (assigned_id = %s OR creator_id = %s) AND progress > 0 AND progress < 100
        """, (user_team_id, user_id))
        in_progress_tasks_result = cursor.fetchone()
        in_progress_tasks = int(in_progress_tasks_result[0]) if in_progress_tasks_result and in_progress_tasks_result[0] is not None else 0

        # 待开始任务数 (progress = 0 或 NULL)
        cursor.execute("""
            SELECT COUNT(*)
            FROM biz_task
            WHERE (assigned_id = %s OR creator_id = %s) AND (progress = 0 OR progress IS NULL)
        """, (user_team_id, user_id))
        pending_tasks_result = cursor.fetchone()
        pending_tasks = int(pending_tasks_result[0]) if pending_tasks_result and pending_tasks_result[0] is not None else 0

        cursor.close()

        # 3. 计算完成率（确保使用 float 类型）
        completion_rate = 0.0
        if total_tasks > 0:
            completion_rate = round((completed_tasks / total_tasks) * 100, 1)

        print(f"📊 用户统计详情:")
        print(f"   - 总任务数: {total_tasks} (类型: {type(total_tasks)})")
        print(f"   - 已完成: {completed_tasks} (类型: {type(completed_tasks)})")
        print(f"   - 进行中: {in_progress_tasks} (类型: {type(in_progress_tasks)})")
        print(f"   - 待开始: {pending_tasks} (类型: {type(pending_tasks)})")
        print(f"   - 完成率: {completion_rate}% (类型: {type(completion_rate)})")

        # 4. 构建响应数据（确保所有数字都是基本类型）
        response_data = {
            "code": 0,
            "data": {
                "total_tasks": total_tasks,
                "completed_tasks": completed_tasks,
                "in_progress_tasks": in_progress_tasks,
                "pending_tasks": pending_tasks,
                "completion_rate": completion_rate
            }
        }

        # 5. 手动验证数据可序列化
        try:
            # 测试数据是否可以 JSON 序列化
            json.dumps(response_data)
            print("✅ 响应数据可以正常序列化")
        except Exception as json_error:
            print(f"❌ JSON 序列化错误: {json_error}")
            # 如果序列化失败，返回安全的数据
            return jsonify({
                "code": 0,
                "data": {
                    "total_tasks": 0,
                    "completed_tasks": 0,
                    "in_progress_tasks": 0,
                    "pending_tasks": 0,
                    "completion_rate": 0.0
                }
            })

        return jsonify(response_data)

    except Exception as e:
        print("❌ 获取用户统计数据异常:", str(e))
        import traceback
        print("详细错误信息:")
        traceback.print_exc()

        # 返回安全的默认数据
        return jsonify({
            "code": 0,
            "data": {
                "total_tasks": 0,
                "completed_tasks": 0,
                "in_progress_tasks": 0,
                "pending_tasks": 0,
                "completion_rate": 0.0
            },
            "msg": "使用默认数据"
        })

# -------------------- 备用统计方案：只查询个人任务 --------------------
@bp.route('/get_personal_stats', methods=['POST'])
def get_personal_stats():
    """只查询个人任务的统计数据（更简单可靠）"""
    data = request.get_json() or {}
    user_id = data.get('user_id')

    if not user_id:
        return jsonify({"code": 1, "msg": "用户ID不能为空"})

    try:
        conn = current_app.db_conn
        cursor = conn.cursor()

        print(f"🔍 开始统计用户 {user_id} 的个人任务数据")

        # 只查询分配给该用户的任务（assigned_id = user_id）
        cursor.execute("SELECT COUNT(*) FROM biz_task WHERE assigned_id = %s", (user_id,))
        total_tasks_result = cursor.fetchone()
        total_tasks = int(total_tasks_result[0]) if total_tasks_result else 0

        cursor.execute("SELECT COUNT(*) FROM biz_task WHERE assigned_id = %s AND progress = 100", (user_id,))
        completed_tasks_result = cursor.fetchone()
        completed_tasks = int(completed_tasks_result[0]) if completed_tasks_result else 0

        cursor.execute("SELECT COUNT(*) FROM biz_task WHERE assigned_id = %s AND progress > 0 AND progress < 100", (user_id,))
        in_progress_tasks_result = cursor.fetchone()
        in_progress_tasks = int(in_progress_tasks_result[0]) if in_progress_tasks_result else 0

        cursor.execute("SELECT COUNT(*) FROM biz_task WHERE assigned_id = %s AND (progress = 0 OR progress IS NULL)", (user_id,))
        pending_tasks_result = cursor.fetchone()
        pending_tasks = int(pending_tasks_result[0]) if pending_tasks_result else 0

        cursor.close()

        # 计算完成率
        completion_rate = 0.0
        if total_tasks > 0:
            completion_rate = round((completed_tasks / total_tasks) * 100, 1)

        print(f"📊 个人任务统计:")
        print(f"   - 总任务数: {total_tasks}")
        print(f"   - 已完成: {completed_tasks}")
        print(f"   - 进行中: {in_progress_tasks}")
        print(f"   - 待开始: {pending_tasks}")
        print(f"   - 完成率: {completion_rate}%")

        return jsonify({
            "code": 0,
            "data": {
                "total_tasks": total_tasks,
                "completed_tasks": completed_tasks,
                "in_progress_tasks": in_progress_tasks,
                "pending_tasks": pending_tasks,
                "completion_rate": completion_rate
            }
        })

    except Exception as e:
        print("❌ 获取个人统计数据异常:", str(e))
        import traceback
        traceback.print_exc()

        return jsonify({
            "code": 0,
            "data": {
                "total_tasks": 0,
                "completed_tasks": 0,
                "in_progress_tasks": 0,
                "pending_tasks": 0,
                "completion_rate": 0.0
            }
        })