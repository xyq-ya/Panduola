# routes.py
from flask import Blueprint, request, jsonify, current_app

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
            "team": team_name
        })

        return jsonify({
            "code": 0,
            "data": {
                "username": name,
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
        data = request.get_json() or {}
        title = data.get('title', '').strip()
        description = data.get('description', '').strip()
        creator_id = data.get('creator_id')
        assigned_type = data.get('assigned_type', 'personal')
        assigned_id = data.get('assigned_id', creator_id)
        start_time = data.get('start_time')
        end_time = data.get('end_time')

        # 验证字段
        if not title or not creator_id or not start_time or not end_time:
            return jsonify({"code": 1, "msg": "缺少必要字段"})

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
            
        cursor = conn.cursor()
        cursor.execute(
            """INSERT INTO biz_task 
               (title, description, creator_id, assigned_type, assigned_id, start_time, end_time, status, progress)
               VALUES (%s, %s, %s, %s, %s, %s, %s, 'pending', 0)""",
            (title, description, creator_id, assigned_type, assigned_id, start_time, end_time)
        )
        task_id = cursor.lastrowid
        conn.commit()
        cursor.close()
        conn.close()
        
        print(f"✅ create_task 成功: id={task_id}, title={title}")
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

        conn = get_db_connection()
        if not conn:
            return jsonify({"code": 500, "msg": "数据库连接失败"})
            
        cursor = conn.cursor()
        
        cursor.execute(
            """
            SELECT t.id, t.title, t.description, t.start_time, t.end_time,
                   t.status, t.progress, t.assigned_type, t.assigned_id,
                   u.name as creator_name
            FROM biz_task t
            LEFT JOIN sys_user u ON t.creator_id = u.id
            WHERE t.creator_id = %s OR t.assigned_id = %s
            ORDER BY t.create_time DESC
            LIMIT 50
            """,
            (user_id, user_id)
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

        # 1. 获取用户所在的团队ID
        cursor.execute("SELECT team_id FROM sys_user WHERE id=%s", (user_id,))
        user_info = cursor.fetchone()

        if not user_info:
            cursor.close()
            conn.close()
            return jsonify({"code": 2, "msg": "用户信息不存在"})

        user_team_id = user_info[0]

        print(f"🔍 调试信息: user_id={user_id}, user_team_id={user_team_id}")

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
        conn.close()

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