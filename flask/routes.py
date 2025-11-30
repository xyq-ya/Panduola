# routes.py
from flask import Blueprint, request, jsonify, current_app
from datetime import datetime
from werkzeug.utils import secure_filename
import os
import time
import pymysql
bp = Blueprint('auth', __name__)

def get_db_connection():
    """获取数据库连接"""
    return current_app.create_db_connection()

# -------------------- 登录 --------------------
@bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    password = data.get('password')
    username = data.get('username')

    if not username or not password:
        return jsonify({"error": "用户名或密码不能为空"}), 400

    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"error": "数据库连接失败"}), 500
            
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
        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
            
        cursor = conn.cursor()
        cursor.execute("SELECT id, dept_name FROM sys_department")
        result = cursor.fetchall()
        cursor.close()
        conn.close()

        dept_list = [{"id": r[0], "dept_name": r[1]} for r in result]
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

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
            
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM sys_department WHERE dept_name=%s", (dept_name,))
        dept = cursor.fetchone()
        if not dept:
            cursor.close()
            conn.close()
            return jsonify({"code": 2, "msg": "部门不存在"})

        dept_id = dept[0]
        cursor.execute("SELECT id, team_name FROM sys_team WHERE department_id=%s", (dept_id,))
        teams = cursor.fetchall()
        cursor.close()
        conn.close()

        team_list = [{"id": t[0], "team_name": t[1]} for t in teams]
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

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
            
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM sys_team WHERE team_name=%s", (team_name,))
        team = cursor.fetchone()
        if not team:
            cursor.close()
            conn.close()
            return jsonify({"code": 2, "msg": "团队不存在"})

        team_id = team[0]
        cursor.execute("SELECT id, name FROM sys_user WHERE team_id=%s", (team_id,))
        users = cursor.fetchall()
        cursor.close()
        conn.close()

        user_list = [{"id": u[0], "username": u[1]} for u in users]
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
        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
            
        cursor = conn.cursor()
        cursor.execute("SELECT name, role_id, team_id FROM sys_user WHERE id=%s", (user_id,))
        user = cursor.fetchone()
        if not user:
            cursor.close()
            conn.close()
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
        conn.close()
        
        print("user_info 返回:", {
            "username": name,
            "role_id": role_id,
            "role_name": role_name,
            "department": dept_name,
            "team": team_name,
            "team_id": team_id  # 新增返回 team_id
        })

        return jsonify({
            "code": 0,
            "data": {
                "username": name,
                "role_id": role_id,
                "role_name": role_name,
                "department": dept_name,
                "team": team_name,
                "team_id": team_id  # 新增返回 team_id
            }
        })

    except Exception as e:
        print("user_info 异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})
@bp.route('/get_task_name', methods=['POST'])
def get_task_name():
    data = request.get_json() or {}
    task_id = data.get('task_id')
    if not task_id:
        return jsonify({'code': 400, 'msg': 'task_id缺失', 'data': ''})

    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            sql = "SELECT title FROM biz_task WHERE id=%s"
            cursor.execute(sql, (task_id,))
            result = cursor.fetchone()
            if result:
                return jsonify({'code': 200, 'msg': '成功', 'data': result[0]})
            else:
                return jsonify({'code': 404, 'msg': '任务不存在', 'data': ''})
    finally:
        conn.close()
@bp.route('/create_task', methods=['POST'])
def create_task():
    try:
        data = request.get_json() or {}

        title = data.get('title', '').strip()
        description = data.get('description', '').strip()
        creator_id = data.get('creator_id')
        assigned_type = data.get('assigned_type', 'personal')
        assigned_id = data.get('assigned_id')
        start_time = data.get('start_time')
        end_time = data.get('end_time')

        # ⭐ 前端传来的是单张图片 URL
        image_url = data.get('image_url', '').strip() if data.get('image_url') else None

        if not title or not creator_id or not assigned_id or not start_time or not end_time:
            return jsonify({"code": 1, "msg": "缺少必要字段"})

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
        cursor = conn.cursor()

        # ------- 根据类型获取真正 assigned_id -------
        if assigned_type == 'dept':
            cursor.execute("SELECT manager_id FROM sys_department WHERE id=%s", (assigned_id,))
            row = cursor.fetchone()
            if row and row[0]:
                assigned_id = row[0]
            else:
                return jsonify({"code": 1, "msg": "部门长不存在"})
        elif assigned_type == 'team':
            cursor.execute("SELECT leader_id FROM sys_team WHERE id=%s", (assigned_id,))
            row = cursor.fetchone()
            if row and row[0]:
                assigned_id = row[0]
            else:
                return jsonify({"code": 1, "msg": "团队长不存在"})

        # ------- 插入任务 -------
        cursor.execute(
            """
            INSERT INTO biz_task 
            (title, description, creator_id, assigned_type, assigned_id,
             start_time, end_time, status, progress, image_url)
            VALUES (%s, %s, %s, %s, %s, %s, %s, 'pending', 0, %s)
            """,
            (title, description, creator_id, assigned_type, assigned_id,
             start_time, end_time, image_url)
        )

        task_id = cursor.lastrowid
        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"code": 0, "msg": "任务创建成功", "data": {"task_id": task_id}})

    except Exception as e:
        print("create_task 异常:", e)
        return jsonify({"code": 500, "msg": f"服务器内部错误: {str(e)}"})

@bp.route('/create_sub_task', methods=['POST'])
def create_sub_task():
    try:
        data = request.get_json() or {}

        title = data.get('title', '').strip()
        description = data.get('description', '').strip()
        creator_id = data.get('creator_id')
        assigned_type = data.get('assigned_type', 'personal')
        assigned_id = data.get('assigned_id')
        start_time = data.get('start_time')
        end_time = data.get('end_time')
        parent_id = data.get('parent_id')

        # ⭐ 单张图片 URL
        image_url = data.get('image_url', '').strip() if data.get('image_url') else None

        if not title or not creator_id or not assigned_id or not start_time or not end_time or not parent_id:
            return jsonify({"code": 1, "msg": "缺少必要字段"})

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
        cursor = conn.cursor()

        # ------- 根据类型获取真正 assigned_id -------
        if assigned_type == 'dept':
            cursor.execute("SELECT manager_id FROM sys_department WHERE id=%s", (assigned_id,))
            row = cursor.fetchone()
            if row and row[0]:
                assigned_id = row[0]
            else:
                return jsonify({"code": 1, "msg": "部门长不存在"})
        elif assigned_type == 'team':
            cursor.execute("SELECT leader_id FROM sys_team WHERE id=%s", (assigned_id,))
            row = cursor.fetchone()
            if row and row[0]:
                assigned_id = row[0]
            else:
                return jsonify({"code": 1, "msg": "团队长不存在"})

        # ------- 插入子任务 -------
        cursor.execute(
            """
            INSERT INTO biz_task
            (title, description, creator_id, assigned_type, assigned_id,
             start_time, end_time, status, progress, parent_id, image_url)
            VALUES (%s, %s, %s, %s, %s, %s, %s, 'pending', 0, %s, %s)
            """,
            (title, description, creator_id, assigned_type, assigned_id,
             start_time, end_time, parent_id, image_url)
        )

        sub_task_id = cursor.lastrowid
        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"code": 0, "msg": "子任务创建成功", "data": {"task_id": sub_task_id}})

    except Exception as e:
        print("create_sub_task 异常:", e)
        return jsonify({"code": 500, "msg": f"服务器内部错误: {str(e)}"})
# -------------------- 获取分配给自己的任务列表 --------------------
@bp.route('/get_tasks', methods=['POST'])
def get_tasks():
    try:
        data = request.get_json() or {}
        user_id = data.get('user_id')
        if not user_id:
            return jsonify({"code": 1, "msg": "缺少用户ID"})

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})

        cursor = conn.cursor()

        # 只获取assigned_id为当前用户的任务
        cursor.execute(
            """
            SELECT t.id, t.title, t.description, t.start_time, t.end_time,
                   t.status, t.progress, t.assigned_type, t.assigned_id,
                   u.name as creator_name
            FROM biz_task t
            LEFT JOIN sys_user u ON t.creator_id = u.id
            WHERE t.assigned_id = %s
            ORDER BY t.create_time DESC
            LIMIT 50
            """,
            (user_id,)
        )

        tasks = cursor.fetchall()
        cursor.close()
        conn.close()

        task_list = []
        for task in tasks:
            task_list.append({
                "id": task[0],
                "title": task[1] or '',
                "description": task[2] or '',
                "start_time": task[3].strftime('%Y-%m-%d %H:%M:%S') if task[3] else '',
                "end_time": task[4].strftime('%Y-%m-%d %H:%M:%S') if task[4] else '',
                "status": task[5] or 'pending',
                "progress": task[6] or 0,
                "assigned_type": task[7] or 'personal',
                "assigned_id": task[8] or user_id,
                "creator_name": task[9] or '',
            })
        return jsonify({"code": 0, "data": task_list})

    except Exception as e:
        print("get_tasks 异常:", e)
        return jsonify({"code": 500, "msg": f"服务器内部错误: {str(e)}"})
# routes.py - 继续修改剩余的路由
@bp.route('/get_logs', methods=['POST'])
def get_logs():
    try:
        data = request.get_json() or {}
        user_id = data.get('user_id')
        if not user_id:
            return jsonify({"code": 1, "msg": "缺少用户ID"})

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})

        cursor = conn.cursor()

        # 查询指定用户的日志，按日期和创建时间倒序
        cursor.execute(
            """
            SELECT id, task_id, content, keywords, image_url, log_date, latitude, longitude
            FROM biz_work_log
            WHERE user_id = %s
            ORDER BY log_date DESC, id DESC
            LIMIT 100
            """,
            (user_id,)
        )

        logs = cursor.fetchall()
        cursor.close()
        conn.close()

        log_list = []
        for log in logs:
            log_list.append({
                "id": log[0],
                "task_id": log[1],
                "content": log[2] or '',
                "keywords": log[3] or '',
                "image_url": log[4] or '',
                "log_date": log[5].strftime('%Y-%m-%d') if log[5] else '',
                "latitude": log[6],   # 新增经度
                "longitude": log[7],  # 新增纬度
            })

        return jsonify({"code": 0, "data": log_list})

    except Exception as e:
        print("get_logs 异常:", e)
        return jsonify({"code": 500, "msg": f"服务器内部错误: {str(e)}"})
# -------------------- AI 分析 --------------------
@bp.route('/ai_analyze', methods=['POST'])
def ai_analyze():
    data = request.get_json() or {}
    text = data.get('text', '')
    model = data.get('model')
    messages = data.get('messages')

    if not text and not data.get('messages'):
        return jsonify({"code": 1, "msg": "缺少 text 或 messages 字段"}), 400

    try:
        from ai_client import analyze_text
        result = analyze_text(text=text, model=model, messages=messages)
        if isinstance(result, dict) and result.get('error'):
            return jsonify({"code": 502, "msg": "外部 AI 调用失败", "detail": str(result.get('error'))}), 502
        if isinstance(result, dict) and 'analysis' in result:
            return jsonify({"code": 0, "data": {"analysis": result['analysis'], **({k:v for k,v in result.items() if k!='analysis'})}})
        return jsonify({"code": 0, "data": result})
    except Exception as e:
        print('ai_analyze 异常:', e)
        return jsonify({"code": 500, "msg": "服务器内部错误", "detail": str(e)}), 500

# -------------------- 数据统计：关键词云 & 趋势 --------------------
@bp.route('/stats_dashboard', methods=['POST'])
def stats_dashboard():
    try:
        data = request.get_json() or {}
        user_id = data.get('user_id')
        days = int(data.get('days', 7))
        if not user_id:
            return jsonify({"code": 400, "msg": "缺少 user_id"}), 400

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
            
        cur = conn.cursor()

        # 计算日期范围
        from datetime import datetime, timedelta
        end_date = datetime.now().date()
        start_date = end_date - timedelta(days=days-1)

        # 近 N 天日志用于关键词统计与趋势
        cur.execute(
            """
            SELECT log_date, keywords, content
            FROM biz_work_log
            WHERE user_id=%s AND log_date BETWEEN %s AND %s
            ORDER BY log_date ASC
            """,
            (user_id, start_date, end_date)
        )
        rows = cur.fetchall()

        # 同期与用户相关的事务（任务）
        cur.execute(
            """
            SELECT title, description
            FROM biz_task
            WHERE (creator_id=%s OR assigned_id=%s)
              AND DATE(update_time) BETWEEN %s AND %s
            ORDER BY update_time DESC
            """,
            (user_id, user_id, start_date, end_date)
        )
        task_rows = cur.fetchall()

        print(f"查询到 {len(rows)} 条日志, {len(task_rows)} 条任务")

        # 1) 关键词聚合
        import re
        word_freq = {}
        
        def add_text_to_freq(text_str: str):
            if not text_str:
                return
            stop_words = {'的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都', '一', '一个'}
            
            for w in re.findall(r"[\u4e00-\u9fa5_a-zA-Z0-9]+", text_str):
                w = w.strip().lower()
                if len(w) <= 1 or w in stop_words:
                    continue
                word_freq[w] = word_freq.get(w, 0) + 1

        for (log_date, kw, content) in rows:
            add_text_to_freq(kw or '')
            add_text_to_freq(content or '')

        for (title, desc) in task_rows:
            add_text_to_freq(title or '')
            add_text_to_freq(desc or '')

        # 2) 趋势数据
        trend_map = {}
        for (log_date, kw, content) in rows:
            k = log_date.strftime('%Y-%m-%d') if hasattr(log_date, 'strftime') else str(log_date)
            trend_map[k] = trend_map.get(k, 0) + 1

        # 填充连续日期
        ordered = []
        for i in range(days):
            d = end_date - timedelta(days=(days-1-i))
            s = d.strftime('%Y-%m-%d')
            ordered.append({"date": s, "count": int(trend_map.get(s, 0))})

        # 3) 任务分类占比
        category_map = {
            '沟通类': ['会议','沟通','同步','讨论','评审','对接'],
            '执行类': ['开发','实现','修复','测试','部署','上线','优化','重构'],
            '规划类': ['规划','计划','设计','方案','评估','调研'],
            '异常处理类': ['异常','故障','告警','回滚','应急','bug']
        }
        category_count = {k: 0 for k in category_map.keys()}
        
        for w, c in word_freq.items():
            matched = False
            for cat, kws in category_map.items():
                if any(kw in w for kw in kws):
                    category_count[cat] += c
                    matched = True
                    break

        cur.close()
        conn.close()
        
        return jsonify({
            "code": 0,
            "data": {
                "keywords": word_freq,
                "trend": ordered,
                "category_ratio": category_count
            }
        })
    except Exception as e:
        print('stats_dashboard 异常:', e)
        return jsonify({"code": 500, "msg": "服务器内部错误", "detail": str(e)}), 500

# -------------------- 公司十大事项（公司层面主事项） --------------------
@bp.route('/company_top_matters', methods=['GET'])
def company_top_matters():
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
            
        cursor = conn.cursor()
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
        conn.close()
        
        data = [{"id": r[0], "title": r[1]} for r in rows]
        return jsonify({"code": 0, "data": data})
    except Exception as e:
        print("company_top_matters 异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

# -------------------- 公司十大派发任务（由高权限派发） --------------------
@bp.route('/company_dispatched_tasks', methods=['GET'])
def company_dispatched_tasks():
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
            
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
        conn.close()
        
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

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
            
        cursor = conn.cursor()
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
        conn.close()
        
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

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
            
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
        conn.close()
        
        data = [
            {"id": r[0], "username": r[1], "content": r[2], "date": r[3].strftime('%Y-%m-%d')}
            for r in rows
        ]
        return jsonify({"code": 0, "data": data})
    except Exception as e:
        print("personal_logs 异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

# -------------------- 获取用户任务数据（用于甘特图） --------------------
@bp.route('/get_user_tasks', methods=['POST'])
def get_user_tasks():
    data = request.get_json() or {}
    user_id = data.get('user_id')

    if not user_id:
        return jsonify({"code": 1, "msg": "缺少用户ID"})

    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})

        cursor = conn.cursor()

        # 只获取与用户本人相关的任务（创建或负责）
        cursor.execute("""
            SELECT
                t.id, t.title, t.description, t.start_time, t.end_time,
                t.progress, t.status, t.creator_id, t.assigned_id,
                u.name as assignee_name,
                creator.name as creator_name
            FROM biz_task t
            LEFT JOIN sys_user u ON t.assigned_id = u.id
            LEFT JOIN sys_user creator ON t.creator_id = creator.id
            WHERE t.assigned_id = %s
            ORDER BY t.start_time
        """, (user_id))

        tasks = cursor.fetchall()

        print(f"🔍 查询结果: 找到 {len(tasks)} 个任务")
        for task in tasks:
            print(f"📋 任务: id={task[0]}, title='{task[1]}', assigned_id={task[8]}, creator_id={task[7]}")

        cursor.close()
        conn.close()

        # 构建返回数据列表
        task_list = []
        for task in tasks:
            color = _get_task_color(task[6], task[5])  # 自定义颜色函数

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
                "final_task_count": len(task_list)
            }
        })

    except Exception as e:
        print("获取任务数据异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})
@bp.route('/get_user_id_by_name', methods=['POST'])
def get_user_id_by_name():
    data = request.get_json()
    name = data.get("username")   # 前端传的是 username，但其实是 “姓名”

    if not name:
        return jsonify({"code": 1, "msg": "缺少参数 username（实际是姓名）"}), 400

    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})

        cursor = conn.cursor()
        cursor.execute("SELECT id, name, team_id, role_id FROM sys_user WHERE name=%s", (name,))
        user = cursor.fetchone()
        cursor.close()
        conn.close()

        if not user:
            return jsonify({"code": 1, "msg": f"用户 '{name}' 不存在"})

        return jsonify({
            "code": 0,
            "data": {
                "id": user[0],
                "name": user[1],
                "team_id": user[2],
                "role_id": user[3]
            }
        })
    except Exception as e:
        print("get_user_id_by_name 异常:", e)
        return jsonify({"code": 500, "msg": f"服务器内部错误: {str(e)}"})
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
# -------------------- 获取全部用户 -------------------- (Web端专用)
@bp.route('/web/all_users', methods=['POST'])
def all_users():
    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
        
        cursor = conn.cursor()
        cursor.execute("""
            SELECT name, mobile, email
            FROM sys_user
        """)
        users = cursor.fetchall()
        cursor.close()
        conn.close()

        user_list = []
        for u in users:
            user_list.append({
                "name": u[0] or "",
                "mobile": u[1] or "",
                "email": u[2] or ""
            })

        return jsonify({"code": 0, "data": user_list})
    except Exception as e:
        print("all_users 异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

@bp.route('/web/select_user', methods=['POST'])
def web_select_user():
    """
    接收 JSON: { "department": "部门名称", "team": "团队名称" }
    返回员工列表，字段名和前端一致: id, name, email, mobile
    """
    try:
        data = request.get_json() or {}
        department_name = data.get("department")
        team_name = data.get("team")

        if not department_name and not team_name:
            return jsonify({"code": 1, "msg": "缺少部门或团队信息"})

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
        cursor = conn.cursor()

        # 如果传了团队名，优先按团队查
        if team_name:
            cursor.execute("SELECT id FROM sys_team WHERE team_name=%s", (team_name,))
            team = cursor.fetchone()
            if not team:
                cursor.close()
                conn.close()
                return jsonify({"code": 2, "msg": "团队不存在"})
            team_id = team[0]
            cursor.execute(
                "SELECT id, name, email, mobile FROM sys_user WHERE team_id=%s",
                (team_id,)
            )
        else:
            # 按部门查询：先查出部门下所有团队，再查团队下的员工
            cursor.execute("SELECT id FROM sys_department WHERE dept_name=%s", (department_name,))
            dept = cursor.fetchone()
            if not dept:
                cursor.close()
                conn.close()
                return jsonify({"code": 3, "msg": "部门不存在"})
            dept_id = dept[0]

            # 获取该部门所有团队id
            cursor.execute("SELECT id FROM sys_team WHERE department_id=%s", (dept_id,))
            teams = cursor.fetchall()
            team_ids = [t[0] for t in teams]
            if not team_ids:
                cursor.close()
                conn.close()
                return jsonify({"code": 0, "data": []})

            # 查询这些团队的员工
            format_strings = ','.join(['%s'] * len(team_ids))
            cursor.execute(
                f"SELECT id, name, email, mobile FROM sys_user WHERE team_id IN ({format_strings})",
                tuple(team_ids)
            )

        users = cursor.fetchall()
        cursor.close()
        conn.close()

        user_list = [
            {
                "id": u[0],
                "name": u[1],
                "email": u[2] or "",
                "mobile": u[3] or ""
            } for u in users
        ]

        return jsonify({"code": 0, "data": user_list})

    except Exception as e:
        print("web_select_user 异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})
# ---------------- 删除用户 ----------------
@bp.route('/web/delete_user', methods=['POST'])
def delete_user():
    data = request.get_json() or {}
    name = data.get('name')
    email = data.get('email')
    mobile = data.get('mobile')

    if not all([name, email, mobile]):
        return jsonify({"code":1, "msg":"缺少用户标识信息"})

    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        # 查找用户
        cursor.execute(
            "SELECT id FROM sys_user WHERE name=%s AND email=%s AND mobile=%s",
            (name, email, mobile)
        )
        user = cursor.fetchone()
        if not user:
            cursor.close()
            conn.close()
            return jsonify({"code":1, "msg":"用户不存在"})
        user_id = user[0]

        # 级联删除相关表
        cursor.execute("DELETE FROM biz_work_log WHERE user_id=%s", (user_id,))
        cursor.execute("DELETE FROM biz_ai_analysis WHERE user_id=%s", (user_id,))
        cursor.execute("DELETE FROM sys_user WHERE id=%s", (user_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"code":0, "msg":"删除成功"})
    except Exception as e:
        conn.rollback()
        cursor.close()
        conn.close()
        return jsonify({"code":1, "msg":f"删除失败: {str(e)}"})


@bp.route('/web/get_user_info', methods=['POST'])
def get_user_info():
    data = request.get_json() or {}
    print("🔹 收到请求数据:", data)  # 打印请求数据
    name = data.get('name')
    email = data.get('email')
    mobile = data.get('mobile')
    
    if not all([name, email, mobile]):
        print("⚠️ 缺少用户标识信息")
        return jsonify({"code":1, "msg":"缺少用户标识信息"})
    
    conn = get_db_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT u.username, u.name, u.password, u.mobile, u.email, 
                   u.role_id, r.role_name, 
                   t.team_name, d.dept_name 
            FROM sys_user u 
            LEFT JOIN sys_role r ON u.role_id=r.id 
            LEFT JOIN sys_team t ON u.team_id=t.id 
            LEFT JOIN sys_department d ON t.department_id=d.id 
            WHERE u.name=%s AND u.email=%s AND u.mobile=%s
            """,
            (name, email, mobile)
        )
        row = cursor.fetchone()
        print("🔹 查询结果 row:", row)  # 打印查询结果
        
        cursor.close()
        conn.close()
        
        if not row:
            print("⚠️ 用户不存在")
            return jsonify({"code":1, "msg":"用户不存在"})
        
        # 索引对应字段
        user_dict = {
            "username": row[0] or "",
            "name": row[1] or "",
            "password": row[2] or "",
            "mobile": row[3] or "",
            "email": row[4] or "",
            "role_id": row[5] or "",  # 新增 role_id
            "role_name": row[6] or "",
            "team_name": row[7] or "",
            "department": row[8] or ""
        }
        print("🔹 返回数据 user_dict:", user_dict)  # 打印最终返回数据
        return jsonify({"code":0, "data": user_dict})
        
    except Exception as e:
        print("❌ 获取用户信息异常:", e)
        return jsonify({"code":1, "msg":f"获取用户信息失败: {str(e)}"})

# ---------------- 编辑用户信息 ----------------
@bp.route('/web/edit_user', methods=['POST'])
def edit_user():
    data = request.get_json() or {}
    orig_name = data.get('orig_name')
    orig_email = data.get('orig_email')
    orig_mobile = data.get('orig_mobile')
    update_fields = data.get('update_fields') or {}

<<<<<<< Updated upstream
    if not all([orig_name, orig_email, orig_mobile]):
        return jsonify({"code":1, "msg":"缺少用户标识信息"})
=======
    print(f"🎯 编辑用户请求:")
    print(f"  原始名称: {orig_name}")
    print(f"  原始邮箱: {orig_email}")
    print(f"  原始手机: {orig_mobile}")
    print(f"  更新字段: {update_fields}")

    # 检查是否提供了用户标识信息
    if not all([orig_name, orig_email, orig_mobile]):
        print("❌ 缺少用户标识信息")
        return jsonify({"code": 1, "msg": "缺少用户标识信息"})
>>>>>>> Stashed changes

    # 邮箱格式验证
    if 'email' in update_fields and update_fields['email']:
        import re
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, update_fields['email']):
            return jsonify({"code": 1, "msg": "邮箱格式不正确"})

    # 手机号格式验证
    if 'mobile' in update_fields and update_fields['mobile']:
        mobile = update_fields['mobile']
        if not mobile.isdigit() or len(mobile) != 11:
            return jsonify({"code": 1, "msg": "手机号必须是11位数字"})

    conn = get_db_connection()
    try:
        cursor = conn.cursor()
<<<<<<< Updated upstream
        # 查找用户
=======

        # 查找用户 - 使用原始信息查找
        print(f"🔍 查询用户: name={orig_name}, email={orig_email}, mobile={orig_mobile}")
>>>>>>> Stashed changes
        cursor.execute(
            "SELECT id, name, email, mobile FROM sys_user WHERE name=%s AND email=%s AND mobile=%s",
            (orig_name, orig_email, orig_mobile)
        )
        user = cursor.fetchone()
        if not user:
            print("❌ 用户不存在")
            cursor.close()
            conn.close()
<<<<<<< Updated upstream
            return jsonify({"code":1, "msg":"用户不存在"})
        user_id = user[0]
=======
            return jsonify({"code": 1, "msg": "用户不存在"})

        user_id, db_name, db_email, db_mobile = user
        print(f"✅ 找到用户: id={user_id}, name={db_name}, email={db_email}, mobile={db_mobile}")

        # 检查邮箱是否已被其他用户使用（排除当前用户）
        if 'email' in update_fields and update_fields['email']:
            cursor.execute(
                "SELECT id FROM sys_user WHERE email=%s AND id != %s",
                (update_fields['email'], user_id)
            )
            if cursor.fetchone():
                cursor.close()
                conn.close()
                return jsonify({"code": 1, "msg": "邮箱已被其他用户使用"})

        # 检查手机号是否已被其他用户使用（排除当前用户）
        if 'mobile' in update_fields and update_fields['mobile']:
            cursor.execute(
                "SELECT id FROM sys_user WHERE mobile=%s AND id != %s",
                (update_fields['mobile'], user_id)
            )
            if cursor.fetchone():
                cursor.close()
                conn.close()
                return jsonify({"code": 1, "msg": "手机号已被其他用户使用"})
>>>>>>> Stashed changes

        update_sql_parts = ["update_time=%s"]
        update_values = [datetime.now()]

<<<<<<< Updated upstream
        # 普通字段
        for key in ['username','name','password','mobile','email']:
            if key in update_fields and update_fields[key] is not None:
                update_sql_parts.append(f"{key}=%s")
                update_values.append(update_fields[key])

        # role_id
        if 'role_name' in update_fields and update_fields['role_name']:
            cursor.execute("SELECT id FROM sys_role WHERE role_name=%s", (update_fields['role_name'],))
            role = cursor.fetchone()
            if role:
                update_sql_parts.append("role_id=%s")
                update_values.append(role[0])
=======
        # 更新普通字段（username, name, mobile, email）
        for key in ['username', 'name', 'mobile', 'email']:
            if key in update_fields and update_fields[key] is not None and update_fields[key] != '':
                update_sql_parts.append(f"{key}=%s")
                update_values.append(update_fields[key])

        # 特殊处理密码字段：只有在新密码不为空时才更新
        if 'password' in update_fields and update_fields['password'] and update_fields['password'] != '':
            update_sql_parts.append("password=%s")
            update_values.append(update_fields['password'])

        # 更新角色权限（role_id）
        if 'role_id' in update_fields and update_fields['role_id']:
            role_id = update_fields['role_id']
            update_sql_parts.append("role_id=%s")
            update_values.append(role_id)
>>>>>>> Stashed changes

        # team_id
        if 'team_name' in update_fields and update_fields['team_name']:
            cursor.execute("SELECT id FROM sys_team WHERE team_name=%s", (update_fields['team_name'],))
            team = cursor.fetchone()
            if team:
                update_sql_parts.append("team_id=%s")
                update_values.append(team[0])

<<<<<<< Updated upstream
        if update_sql_parts:
            update_values.append(user_id)
=======
        # 如果有需要更新的字段，执行更新操作
        if len(update_sql_parts) > 1:  # 大于1表示除了update_time还有其他字段
            update_values.append(user_id)  # 最后一个是用户ID
>>>>>>> Stashed changes
            sql = f"UPDATE sys_user SET {', '.join(update_sql_parts)} WHERE id=%s"
            print(f"🔹 执行SQL: {sql}")
            print(f"🔹 参数: {update_values}")
            cursor.execute(sql, update_values)
            conn.commit()
            cursor.close()
            conn.close()
            return jsonify({"code":0, "msg":"修改成功"})
        else:
            cursor.close()
            conn.close()
            return jsonify({"code":1, "msg":"没有需要更新的字段"})

    except Exception as e:
        conn.rollback()
        cursor.close()
        conn.close()
<<<<<<< Updated upstream
        return jsonify({"code":1, "msg":f"修改失败: {str(e)}"})
=======
        print(f"❌ 修改用户异常: {e}")
        return jsonify({"code": 1, "msg": f"修改失败: {str(e)}"})

>>>>>>> Stashed changes
# -------------------- 获取任务详情 --------------------
@bp.route('/get_task_detail', methods=['POST'])
def get_task_detail():
    try:
        data = request.get_json() or {}
        task_id = data.get('task_id')

        if not task_id:
            return jsonify({"code": 1, "msg": "缺少任务ID"})

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})

        cursor = conn.cursor()

        # SQL 查询，同时返回 creator_id、assigned_id、assigned_type 和对应名字
        cursor.execute(
            """
            SELECT t.id, t.title, t.description, t.start_time, t.end_time,
                t.status, t.progress,
                t.creator_id, t.assigned_id, t.assigned_type,
                u1.name AS creator_name,
                u2.name AS assigned_name,
                t.image_url   -- 新加这一列
            FROM biz_task t
            LEFT JOIN sys_user u1 ON t.creator_id = u1.id
            LEFT JOIN sys_user u2 ON t.assigned_id = u2.id
            WHERE t.id = %s
            """,
            (task_id,)
        )

        task = cursor.fetchone()
        # ...

        task_detail = {
            "id": task[0],
            "title": task[1] or '',
            "description": task[2] or '',
            "start_time": task[3].strftime('%Y-%m-%d %H:%M:%S') if task[3] else '',
            "end_time": task[4].strftime('%Y-%m-%d %H:%M:%S') if task[4] else '',
            "status": task[5] or 'pending',
            "progress": task[6] or 0,
            "creator_id": task[7],
            "assigned_id": task[8],
            "assigned_type": task[9] or 'personal',
            "creator_name": task[10] or '',
            "assigned_name": task[11] or '',
            "image_url": task[12] or '',  # 返回 image_url
        }

        return jsonify({"code": 0, "data": task_detail})

    except Exception as e:
        print(f"❌ 获取任务详情异常: {e}")
        return jsonify({"code": 500, "msg": "服务器异常"})
@bp.route('/get_sub_tasks', methods=['POST'])
def get_sub_tasks():
    try:
        data = request.get_json() or {}
        task_id = data.get("task_id")

        if not task_id:
            return jsonify({"code": 1, "msg": "task_id 不能为空"})

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})

        cursor = conn.cursor()

        # 查询子任务及负责人姓名
        sql = """
            SELECT t.id, t.title, t.status, t.progress, u.name as assigned_name,
                   t.start_time, t.end_time
            FROM biz_task t
            LEFT JOIN sys_user u ON t.assigned_id = u.id
            WHERE t.parent_id = %s
            ORDER BY t.id ASC
        """
        cursor.execute(sql, (task_id,))
        rows = cursor.fetchall()

        cursor.close()
        conn.close()

        sub_task_list = []
        for row in rows:
            sub_task_list.append({
                "id": row[0],
                "title": row[1] or "",
                "status": row[2] or "pending",
                "progress": row[3] or 0,
                "assigned_name": row[4] or "未指定",
                "start_time": row[5].strftime('%Y-%m-%d %H:%M:%S') if row[5] else "",
                "end_time": row[6].strftime('%Y-%m-%d %H:%M:%S') if row[6] else "",
            })

        return jsonify({"code": 0, "msg": "success", "data": sub_task_list})

    except Exception as e:
        print("❌ 获取子任务异常:", e)
        return jsonify({"code": 500, "msg": f"服务器错误: {str(e)}"})
# -------------------- 获取任务可分发对象（直接用前端传的 assigned_type/assigned_id） --------------------
@bp.route('/get_task_targets', methods=['POST'])
def get_task_targets():
    try:
        data = request.get_json() or {}
        assigned_type = data.get('assigned_type')  # 前端传入 dept/team/personal
        assigned_id = data.get('assigned_id')      # 对应部门ID / 团队ID / 用户ID

        if not assigned_type or not assigned_id:
            return jsonify({"code": 1, "msg": "缺少 assigned_type 或 assigned_id"})

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
        cursor = conn.cursor(pymysql.cursors.DictCursor)

        data_list = []
        if assigned_type == 'dept':
            # 主任务分配给部门 → 子任务可分配给部门下的团队
            cursor.execute(
                "SELECT id, team_name FROM sys_team WHERE department_id=%s",
                (assigned_id,)
            )
            data_list = cursor.fetchall()

        elif assigned_type == 'team':
            # 主任务分配给团队 → 子任务可分配给团队下的成员
            cursor.execute(
                "SELECT id, username, name FROM sys_user WHERE team_id=%s",
                (assigned_id,)
            )
            data_list = cursor.fetchall()

        else:
            cursor.close()
            conn.close()
            return jsonify({"code": 1, "msg": f"未知 assigned_type: {assigned_type}"})

        cursor.close()
        conn.close()
        return jsonify({"code": 0, "data": data_list})

    except Exception as e:
        print("get_task_targets 异常:", e)
        return jsonify({"code": 1, "msg": f"获取分发列表失败: {str(e)}"})
# -------------------- 提交工作日志 & 更新任务进度（递归更新父任务） --------------------
@bp.route('/create_work_log', methods=['POST'])
def create_work_log():
    try:
        data = request.get_json() or {}
        task_id = data.get('task_id')
        user_id = data.get('user_id')
        content = data.get('content', '').strip()
        keywords = data.get('keywords', '').strip()
        image_url = data.get('image_url', '').strip() if data.get('image_url') else None
        log_date = data.get('log_date')
        progress = data.get('progress', 0)
        latitude = data.get('latitude')
        longitude = data.get('longitude')

        # 参数校验
        if not task_id or not user_id:
            return jsonify({"code": 1, "msg": "缺少 task_id 或 user_id"})
        if not content:
            return jsonify({"code": 1, "msg": "工作内容不能为空"})
        if not log_date:
            return jsonify({"code": 1, "msg": "日志日期不能为空"})
        if not isinstance(progress, int) or progress < 0 or progress > 100:
            return jsonify({"code": 1, "msg": "完成进度必须为 0-100 的整数"})

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
        cursor = conn.cursor(pymysql.cursors.DictCursor)

        # 查询任务当前进度
        cursor.execute("SELECT progress, parent_id FROM biz_task WHERE id=%s", (task_id,))
        row = cursor.fetchone()
        if not row:
            cursor.close()
            conn.close()
            return jsonify({"code": 1, "msg": "任务不存在"})
        
        current_progress = row['progress']
        if progress < current_progress:
            cursor.close()
            conn.close()
            return jsonify({
                "code": 1,
                "msg": f"新的进度({progress}%)不能低于当前进度({current_progress}%)"
            })

        # 插入工作日志
        insert_sql = """
            INSERT INTO biz_work_log
            (task_id, user_id, content, keywords, image_url, log_date, latitude, longitude)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(insert_sql, (
            task_id, user_id, content, keywords, image_url, log_date, latitude, longitude
        ))

        # 更新任务进度和状态的函数
        def update_task_progress(t_id, new_progress):
            cursor.execute("SELECT progress, parent_id FROM biz_task WHERE id=%s", (t_id,))
            t = cursor.fetchone()
            if not t:
                return
            current = t['progress']
            if new_progress < current:
                return  # 不可倒退

            # 更新当前任务状态
            status = 'pending'
            if new_progress == 100:
                status = 'completed'
            elif new_progress > 0:
                status = 'in_progress'

            cursor.execute(
                "UPDATE biz_task SET progress=%s, status=%s, update_time=NOW() WHERE id=%s",
                (new_progress, status, t_id)
            )

            # 更新父任务平均进度并递归
            parent_id = t['parent_id']
            if parent_id:
                cursor.execute(
                    "SELECT AVG(progress) AS avg_progress FROM biz_task WHERE parent_id=%s",
                    (parent_id,)
                )
                avg_progress = cursor.fetchone()['avg_progress'] or 0
                update_task_progress(parent_id, round(avg_progress))

        # 执行更新
        update_task_progress(task_id, progress)

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"code": 0, "msg": "提交成功"})

    except Exception as e:
        print("create_work_log 异常:", e)
        return jsonify({"code": 1, "msg": f"提交失败: {str(e)}"})
# -------------------- 上传图片接口 --------------------
@bp.route('/upload_work_log_image', methods=['POST'])
def upload_work_log_image():
    try:
        if 'file' not in request.files:
            return jsonify({"code": 1, "msg": "未上传文件"})
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({"code": 1, "msg": "文件名为空"})
        
        # 保存路径，可以根据需要改
        upload_folder = os.path.join(current_app.root_path, 'static', 'uploads', 'work_log')
        os.makedirs(upload_folder, exist_ok=True)
        
        # 生成唯一文件名
        filename = f"{int(time.time())}_{secure_filename(file.filename)}"
        file_path = os.path.join(upload_folder, filename)
        file.save(file_path)
        
        # 返回可访问 URL
        url = f"/static/uploads/work_log/{filename}"
        return jsonify({"code": 0, "url": url, "msg": "上传成功"})
    
    except Exception as e:
        print("upload_work_image 异常:", e)
        return jsonify({"code": 1, "msg": f"上传失败: {str(e)}"})

# -------------------- 上传图片接口 --------------------
@bp.route('/upload_work_image', methods=['POST'])
def upload_work_image():
    try:
        if 'file' not in request.files:
            return jsonify({"code": 1, "msg": "未上传文件"})
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({"code": 1, "msg": "文件名为空"})
        
        # 保存路径，可以根据需要改
        upload_folder = os.path.join(current_app.root_path, 'static', 'uploads', 'work')
        os.makedirs(upload_folder, exist_ok=True)
        
        # 生成唯一文件名
        filename = f"{int(time.time())}_{secure_filename(file.filename)}"
        file_path = os.path.join(upload_folder, filename)
        file.save(file_path)
        
        # 返回可访问 URL
        url = f"/static/uploads/work/{filename}"
        return jsonify({"code": 0, "url": url, "msg": "上传成功"})
    
    except Exception as e:
        print("upload_work_image 异常:", e)
        return jsonify({"code": 1, "msg": f"上传失败: {str(e)}"})
# -------------------- 获取团队成员信息 --------------------
@bp.route('/get_team_members', methods=['POST'])
def get_team_members():
    data = request.get_json() or {}
    team_id = data.get('team_id')
    current_user_id = data.get('current_user_id')

    if not team_id:
        return jsonify({"code": 1, "msg": "团队ID不能为空"})

    try:
        conn = get_db_connection()  # 直接获取数据库连接
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})

        cursor = conn.cursor()
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
        conn.close()

        members_data = []
        for member in members:
            members_data.append({
                "id": member[0],
                "username": member[1],
                "name": member[2],
                "email": member[3],
                "mobile": member[4],
                "role_name": member[5],
                "isCurrentUser": member[0] == current_user_id
            })

        return jsonify({
            "code": 0,
            "data": members_data
        })

    except Exception as e:
        print("获取团队成员异常:", e)
        import traceback
        traceback.print_exc()
        return jsonify({"code": 500, "msg": f"服务器内部错误: {e}"})


# -------------------- 获取用户任务统计数据 --------------------
@bp.route('/get_user_stats', methods=['POST'])
def get_user_stats():
    data = request.get_json() or {}
    user_id = data.get('user_id')

    if not user_id:
        return jsonify({"code": 1, "msg": "用户ID不能为空"})

    try:
        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})

        cursor = conn.cursor()
        cursor.execute("SELECT id, team_id FROM sys_user WHERE id=%s", (user_id,))
        user_info = cursor.fetchone()
        if not user_info:
            cursor.close()
            return jsonify({"code": 2, "msg": "用户信息不存在"})

        user_team_id = user_info[1]

        # 总任务数
        cursor.execute("""
            SELECT COUNT(*) FROM biz_task WHERE assigned_id=%s OR creator_id=%s
        """, (user_team_id, user_id))
        total_tasks = cursor.fetchone()[0] or 0

        # 已完成任务数
        cursor.execute("""
            SELECT COUNT(*) FROM biz_task WHERE (assigned_id=%s OR creator_id=%s) AND progress=100
        """, (user_team_id, user_id))
        completed_tasks = cursor.fetchone()[0] or 0

        # 进行中任务
        cursor.execute("""
            SELECT COUNT(*) FROM biz_task WHERE (assigned_id=%s OR creator_id=%s) AND progress>0 AND progress<100
        """, (user_team_id, user_id))
        in_progress_tasks = cursor.fetchone()[0] or 0

        # 待开始任务
        cursor.execute("""
            SELECT COUNT(*) FROM biz_task WHERE (assigned_id=%s OR creator_id=%s) AND (progress=0 OR progress IS NULL)
        """, (user_team_id, user_id))
        pending_tasks = cursor.fetchone()[0] or 0

        cursor.close()
        conn.close()

        completion_rate = round((completed_tasks / total_tasks) * 100, 1) if total_tasks else 0.0

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
        print("获取用户统计数据异常:", e)
        import traceback
        traceback.print_exc()
        return jsonify({"code": 500, "msg": f"服务器内部错误: {e}"})
@bp.route('/get_user_info_byid', methods=['POST'])
def get_user_info_byid():
    data = request.get_json() or {}
    user_id = data.get('user_id')
    if not user_id:
        return jsonify({'code': 400, 'msg': 'user_id缺失', 'data': {}})

    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            sql = "SELECT username, password, name, email, mobile FROM sys_user WHERE id=%s"
            cursor.execute(sql, (user_id,))
            result = cursor.fetchone()
            if result:
                return jsonify({
                    'code': 200,
                    'msg': '成功',
                    'data': {
                        'username': result[0],
                        'password': result[1],
                        'name': result[2],
                        'email': result[3],
                        'mobile': result[4]
                    }
                })
            else:
                return jsonify({'code': 404, 'msg': '用户不存在', 'data': {}})
    finally:
        conn.close()
@bp.route('/update_user_info', methods=['POST'])
def update_user_info():
    data = request.get_json() or {}
    user_id = data.get('user_id')
    if not user_id:
        return jsonify({'code': 400, 'msg': 'user_id缺失'})

    username = data.get('username')
    password = data.get('password')  # 可存明文或加密
    name = data.get('name')
    email = data.get('email')
    mobile = data.get('mobile')

    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            sql = """
                UPDATE sys_user
                SET username=%s, password=%s, name=%s, email=%s, mobile=%s
                WHERE id=%s
            """
            cursor.execute(sql, (username, password, name, email, mobile, user_id))
            conn.commit()
            if cursor.rowcount > 0:
                return jsonify({'code': 200, 'msg': '更新成功'})
            else:
                return jsonify({'code': 404, 'msg': '用户不存在或未修改'})
    finally:
        conn.close()
<<<<<<< Updated upstream
=======
@bp.route('/get_unread_message_count', methods=['POST'])
def get_unread_message_count():
    try:
        data = request.get_json() or {}
        user_id = data.get('user_id')

        if not user_id:
            return jsonify({"code": 1, "msg": "缺少 user_id"})

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute(
            "SELECT COUNT(*) FROM biz_message WHERE user_id=%s AND is_read=0",
            (user_id,)
        )
        count = cursor.fetchone()[0]

        cursor.close()
        conn.close()

        return jsonify({"code": 0, "msg": "成功", "data": {"count": count}})

    except Exception as e:
        print("get_unread_message_count 异常:", e)
        return jsonify({"code": 500, "msg": f"服务器内部错误: {str(e)}"})
@bp.route('/get_user_messages', methods=['POST'])
def get_user_messages():
    try:
        data = request.get_json() or {}
        user_id = data.get("user_id")

        if not user_id:
            return jsonify({"code": 1, "msg": "缺少 user_id"})

        conn = get_db_connection()
        cursor = conn.cursor()

        # 查询消息
        cursor.execute("""
            SELECT id, task_id, content, is_read, create_time
            FROM biz_message
            WHERE user_id = %s
            ORDER BY create_time DESC
        """, (user_id,))
        raw_messages = cursor.fetchall()

        messages = []
        message_ids_to_update = []

        for row in raw_messages:
            msg_id = row[0]
            task_id = row[1]
            content = row[2]
            is_read = row[3]
            create_time = row[4]

            # 查询任务名
            cursor.execute("SELECT title FROM biz_task WHERE id=%s", (task_id,))
            task_res = cursor.fetchone()
            task_name = task_res[0] if task_res else "(任务不存在)"

            messages.append({
                "id": msg_id,
                "task_id": task_id,
                "task_name": task_name,
                "content": content,
                "is_read": is_read,  # 前端显示原始值
                "created_time": str(create_time)
            })

            # 收集未读消息 ID
            if is_read == 0:
                message_ids_to_update.append(msg_id)

        # 返回给前端后，批量更新数据库
        if message_ids_to_update:
            format_strings = ",".join(["%s"] * len(message_ids_to_update))
            cursor.execute(f"""
                UPDATE biz_message
                SET is_read = 1
                WHERE id IN ({format_strings})
            """, tuple(message_ids_to_update))
            conn.commit()

        cursor.close()
        conn.close()

        return jsonify({"code": 0, "msg": "成功", "data": messages})

    except Exception as e:
        print("get_user_messages 异常:", e)
        return jsonify({"code": 500, "msg": f"服务器错误: {str(e)}"})
@bp.route('web/select_roles', methods=['POST'])
def select_roles():
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            sql = "SELECT id, role_name FROM sys_role"
            cursor.execute(sql)
            roles = cursor.fetchall()
        conn.close()
        return jsonify({"code": 0, "msg": "获取成功", "data": roles})
    except Exception as e:
        print("获取角色列表失败:", e)
        return jsonify({"code": 1, "msg": "获取角色列表失败", "data": []})

# -------------------- 新增用户接口 --------------------
@bp.route('/web/add_user', methods=['POST'])
def add_user():
    try:
        data = request.get_json() or {}

        username = data.get('username', '').strip()
        password = data.get('password', '').strip()
        name = data.get('name', '').strip()
        mobile = data.get('mobile', '').strip()
        email = data.get('email', '').strip()
        dept_name = data.get('dept_name')
        team_name = data.get('team_name')
        role_id = data.get('role_id')

        # 必填字段验证
        if not all([username, password, name, mobile, email]):
            return jsonify({"code": 1, "msg": "用户名、密码、姓名、手机、邮箱为必填项"})

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})

        cursor = conn.cursor()

        # 检查用户名是否已存在
        cursor.execute("SELECT id FROM sys_user WHERE username=%s", (username,))
        if cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"code": 1, "msg": "用户名已存在"})

        # 插入新用户
        cursor.execute(
            """
            INSERT INTO sys_user
            (username, password, name, mobile, email, team_id, role_id, create_time, update_time)
            VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
            """,
            (username, password, name, mobile, email, None, role_id)
        )

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"code": 0, "msg": "用户创建成功"})

    except Exception as e:
        print("add_user 异常:", e)
        return jsonify({"code": 500, "msg": f"服务器内部错误: {str(e)}"})

# -------------------- 部门管理接口 --------------------
@bp.route('/web/departments', methods=['GET'])
def get_all_departments():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT d.id, d.dept_name, d.manager_id, u.name as manager_name,
                   d.create_time, d.update_time
            FROM sys_department d
            LEFT JOIN sys_user u ON d.manager_id = u.id
            ORDER BY d.id
        """)
        departments = cursor.fetchall()

        cursor.close()
        conn.close()

        dept_list = []
        for dept in departments:
            dept_list.append({
                "id": dept[0],
                "dept_name": dept[1],
                "manager_id": dept[2],
                "manager_name": dept[3] or "未设置",
                "create_time": dept[4].strftime('%Y-%m-%d %H:%M:%S') if dept[4] else '',
                "update_time": dept[5].strftime('%Y-%m-%d %H:%M:%S') if dept[5] else ''
            })

        return jsonify({"code": 0, "data": dept_list})

    except Exception as e:
        print("获取部门列表异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

@bp.route('/web/departments/add', methods=['POST'])
def add_department():
    try:
        data = request.get_json() or {}
        dept_name = data.get('dept_name', '').strip()
        manager_id = data.get('manager_id')

        if not dept_name:
            return jsonify({"code": 1, "msg": "部门名称不能为空"})

        conn = get_db_connection()
        cursor = conn.cursor()

        # 检查部门名是否已存在
        cursor.execute("SELECT id FROM sys_department WHERE dept_name=%s", (dept_name,))
        if cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"code": 1, "msg": "部门名称已存在"})

        # 插入新部门
        cursor.execute(
            "INSERT INTO sys_department (dept_name, manager_id, create_time, update_time) VALUES (%s, %s, NOW(), NOW())",
            (dept_name, manager_id)
        )

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"code": 0, "msg": "部门创建成功"})

    except Exception as e:
        print("添加部门异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

@bp.route('/web/departments/update', methods=['POST'])
def update_department():
    try:
        data = request.get_json() or {}
        dept_id = data.get('id')
        dept_name = data.get('dept_name', '').strip()
        manager_id = data.get('manager_id')

        if not dept_id or not dept_name:
            return jsonify({"code": 1, "msg": "部门ID和名称不能为空"})

        conn = get_db_connection()
        cursor = conn.cursor()

        # 检查部门名是否被其他部门使用
        cursor.execute("SELECT id FROM sys_department WHERE dept_name=%s AND id != %s", (dept_name, dept_id))
        if cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"code": 1, "msg": "部门名称已被其他部门使用"})

        # 更新部门
        cursor.execute(
            "UPDATE sys_department SET dept_name=%s, manager_id=%s, update_time=NOW() WHERE id=%s",
            (dept_name, manager_id, dept_id)
        )

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"code": 0, "msg": "部门更新成功"})

    except Exception as e:
        print("更新部门异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

@bp.route('/web/departments/delete', methods=['POST'])
def delete_department():
    try:
        data = request.get_json() or {}
        dept_id = data.get('id')

        if not dept_id:
            return jsonify({"code": 1, "msg": "部门ID不能为空"})

        conn = get_db_connection()
        cursor = conn.cursor()

        # 检查部门下是否有团队
        cursor.execute("SELECT COUNT(*) FROM sys_team WHERE department_id=%s", (dept_id,))
        team_count = cursor.fetchone()[0]
        if team_count > 0:
            cursor.close()
            conn.close()
            return jsonify({"code": 1, "msg": "该部门下还有团队，无法删除"})

        # 删除部门
        cursor.execute("DELETE FROM sys_department WHERE id=%s", (dept_id,))

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"code": 0, "msg": "部门删除成功"})

    except Exception as e:
        print("删除部门异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

# -------------------- 团队管理接口 --------------------
@bp.route('/web/teams', methods=['GET'])
def get_all_teams():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT t.id, t.team_name, t.department_id, d.dept_name,
                   t.leader_id, u.name as leader_name,
                   t.create_time, t.update_time
            FROM sys_team t
            LEFT JOIN sys_department d ON t.department_id = d.id
            LEFT JOIN sys_user u ON t.leader_id = u.id
            ORDER BY t.id
        """)
        teams = cursor.fetchall()

        cursor.close()
        conn.close()

        team_list = []
        for team in teams:
            team_list.append({
                "id": team[0],
                "team_name": team[1],
                "department_id": team[2],
                "dept_name": team[3] or "未分配",
                "leader_id": team[4],
                "leader_name": team[5] or "未设置",
                "create_time": team[6].strftime('%Y-%m-%d %H:%M:%S') if team[6] else '',
                "update_time": team[7].strftime('%Y-%m-%d %H:%M:%S') if team[7] else ''
            })

        print(f"🔍 返回团队数据: {len(team_list)} 条记录")  # 调试信息
        for team in team_list:
            print(f"📋 团队: id={team['id']}, name={team['team_name']}, dept={team['dept_name']}")

        return jsonify({"code": 0, "data": team_list})

    except Exception as e:
        print("获取团队列表异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

@bp.route('/web/teams/add', methods=['POST'])
def add_team():
    try:
        data = request.get_json() or {}
        team_name = data.get('team_name', '').strip()
        department_id = data.get('department_id')
        leader_id = data.get('leader_id')

        if not team_name:
            return jsonify({"code": 1, "msg": "团队名称不能为空"})

        if not department_id:
            return jsonify({"code": 1, "msg": "请选择所属部门"})

        conn = get_db_connection()
        cursor = conn.cursor()

        # 检查团队名是否已存在
        cursor.execute("SELECT id FROM sys_team WHERE team_name=%s", (team_name,))
        if cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"code": 1, "msg": "团队名称已存在"})

        # 插入新团队
        cursor.execute(
            "INSERT INTO sys_team (team_name, department_id, leader_id, create_time, update_time) VALUES (%s, %s, %s, NOW(), NOW())",
            (team_name, department_id, leader_id)
        )

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"code": 0, "msg": "团队创建成功"})

    except Exception as e:
        print("添加团队异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

@bp.route('/web/teams/update', methods=['POST'])
def update_team():
    try:
        data = request.get_json() or {}
        team_id = data.get('id')
        team_name = data.get('team_name', '').strip()
        department_id = data.get('department_id')
        leader_id = data.get('leader_id')

        if not team_id or not team_name or not department_id:
            return jsonify({"code": 1, "msg": "团队ID、名称和部门不能为空"})

        conn = get_db_connection()
        cursor = conn.cursor()

        # 检查团队名是否被其他团队使用
        cursor.execute("SELECT id FROM sys_team WHERE team_name=%s AND id != %s", (team_name, team_id))
        if cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"code": 1, "msg": "团队名称已被其他团队使用"})

        # 更新团队
        cursor.execute(
            "UPDATE sys_team SET team_name=%s, department_id=%s, leader_id=%s, update_time=NOW() WHERE id=%s",
            (team_name, department_id, leader_id, team_id)
        )

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"code": 0, "msg": "团队更新成功"})

    except Exception as e:
        print("更新团队异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

@bp.route('/web/teams/delete', methods=['POST'])
def delete_team():
    try:
        data = request.get_json() or {}
        team_id = data.get('id')

        if not team_id:
            return jsonify({"code": 1, "msg": "团队ID不能为空"})

        conn = get_db_connection()
        cursor = conn.cursor()

        # 检查团队下是否有成员
        cursor.execute("SELECT COUNT(*) FROM sys_user WHERE team_id=%s", (team_id,))
        user_count = cursor.fetchone()[0]
        if user_count > 0:
            cursor.close()
            conn.close()
            return jsonify({"code": 1, "msg": "该团队下还有成员，无法删除"})

        # 检查是否有任务分配给该团队
        cursor.execute("SELECT COUNT(*) FROM biz_task WHERE assigned_type='team' AND assigned_id=%s", (team_id,))
        task_count = cursor.fetchone()[0]
        if task_count > 0:
            cursor.close()
            conn.close()
            return jsonify({"code": 1, "msg": "有任务分配给该团队，无法删除"})

        # 删除团队
        cursor.execute("DELETE FROM sys_team WHERE id=%s", (team_id,))

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"code": 0, "msg": "团队删除成功"})

    except Exception as e:
        print("删除团队异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

@bp.route('/web/teams/change_leader', methods=['POST'])
def change_team_leader():
    try:
        data = request.get_json() or {}
        team_id = data.get('team_id')
        new_leader_id = data.get('new_leader_id')

        if not team_id or not new_leader_id:
            return jsonify({"code": 1, "msg": "团队ID和新团队长ID不能为空"})

        conn = get_db_connection()
        cursor = conn.cursor()

        # 检查新团队长是否属于该团队
        cursor.execute("SELECT id FROM sys_user WHERE id=%s AND team_id=%s", (new_leader_id, team_id))
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"code": 1, "msg": "新团队长不属于该团队"})

        # 更新团队长
        cursor.execute(
            "UPDATE sys_team SET leader_id=%s, update_time=NOW() WHERE id=%s",
            (new_leader_id, team_id)
        )

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({"code": 0, "msg": "团队长更换成功"})

    except Exception as e:
        print("更换团队长异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})

@bp.route('/web/available_managers', methods=['POST'])
def get_available_managers():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # 获取所有用户，用于选择部门经理
        cursor.execute("""
            SELECT id, name, username
            FROM sys_user
            WHERE role_id IN (1, 2, 3)  -- 只允许管理员、部门老总、部门经理作为部门经理
            ORDER BY name
        """)
        managers = cursor.fetchall()

        cursor.close()
        conn.close()

        manager_list = [{"id": m[0], "name": m[1], "username": m[2]} for m in managers]
        return jsonify({"code": 0, "data": manager_list})

    except Exception as e:
        print("获取可用经理异常:", e)
        return jsonify({"code": 500, "msg": "服务器内部错误"})
>>>>>>> Stashed changes
