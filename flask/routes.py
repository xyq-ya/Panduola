# routes.py
from flask import Blueprint, request, jsonify, current_app

bp = Blueprint('auth', __name__)

def mock_login_response(username):
    # 返回与真实接口相同字段的示例
    if username == 'admin':
        return {'id': 1}
    return {'id': 100}

def mock_select_department():
    return {"code": 0, "data": [{"id": 1, "dept_name": "技术部"}, {"id": 2, "dept_name": "市场部"}]}

def mock_select_team(department):
    return {"code": 0, "data": [{"id": 1, "team_name": "前端开发团队"}, {"id": 2, "team_name": "后端开发团队"}]}

def mock_select_user(team):
    return {"code": 0, "data": [{"id": 1, "username": "张三"}, {"id": 2, "username": "李四"}]}

def mock_user_info(user_id):
    return {"code": 0, "data": {"username": "张三", "role_id": 5, "role_name": "普通员工", "department": "技术部", "team": "前端开发团队"}}

# -------------------- 登录 --------------------
@bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    password = data.get('password')
    username = data.get('username')  # 虽然 Flutter 不用，但保留接口验证

    if not username or not password:
        return jsonify({"error": "用户名或密码不能为空"}), 400

    # mock 模式下返回示例数据（无需数据库）
    if current_app.config.get('MOCK_DB'):
        return jsonify(mock_login_response(username))

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
        if current_app.config.get('MOCK_DB'):
            return jsonify(mock_select_department())

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

        if current_app.config.get('MOCK_DB'):
            return jsonify(mock_select_team(dept_name))

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

        if current_app.config.get('MOCK_DB'):
            return jsonify(mock_select_user(team_name))

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

    if current_app.config.get('MOCK_DB'):
        return jsonify(mock_user_info(user_id))

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


# -------------------- AI 分析（外部或 Mock） --------------------
@bp.route('/ai_analyze', methods=['POST'])
def ai_analyze():
    data = request.get_json() or {}
    text = data.get('text', '')
    model = data.get('model')
    messages = data.get('messages')

    # Accept either a plain `text` string or a `messages` list for multi-turn conversation
    if not text and not data.get('messages'):
        return jsonify({"code": 1, "msg": "缺少 text 或 messages 字段"}), 400


    # 也就是说只要配置了 ARK_API_KEY（或 AI_API_URL），将尝试调用外部 AI
    if current_app.config.get('MOCK_DB') or (not current_app.config.get('AI_API_URL') and not current_app.config.get('ARK_API_KEY')):
        # 简单关键词频率统计作为示例分析输出
        words = {}
        for w in __import__('re').findall(r"[\u4e00-\u9fa5_a-zA-Z0-9]+", text):
            w = w.lower()
            if len(w) > 1:
                words[w] = words.get(w, 0) + 1

        # 构造简单建议（与客户端本地逻辑一致的简易版）
        high = [k for k, v in words.items() if v >= 2]
        lines = []
        if any('会议' in h or '沟通' in h for h in high):
            lines.append('行为特征：偏向协作与沟通。建议：减少会议时长并明确议程。')
        if any('文档' in h or '设计' in h or '调研' in h for h in high):
            lines.append('行为特征：偏向独立执行与研究。建议：安排更多同步时间以便让产出落地。')
        if not lines:
            lines.append('行为特征：均衡。建议：保持当前工作方式并关注关键阻塞项。')

        return jsonify({"code": 0, "data": {"analysis": '\n'.join(lines), "keywords": words}})

    # 否则尝试调用外部 AI 服务
    try:
        # Use absolute import because Flask app is run as a script in development
        from ai_client import analyze_text
        # If the client sent a messages array (multi-turn), pass it through; otherwise pass text
        result = analyze_text(text=text, model=model, messages=messages)
        # 如果外部返回 error，转换为 500
        if isinstance(result, dict) and result.get('error'):
            return jsonify({"code": 502, "msg": "外部 AI 调用失败", "detail": str(result.get('error'))}), 502
        # 规范化返回：如果 result 包含 'analysis'，将其包在 data.analysis
        if isinstance(result, dict) and 'analysis' in result:
            return jsonify({"code": 0, "data": {"analysis": result['analysis'], **({k:v for k,v in result.items() if k!='analysis'})}})
        # 否则直接尝试透传
        return jsonify({"code": 0, "data": result})
    except Exception as e:
        # 返回详细错误以便本地调试（生产环境请移除 detail）
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

        conn = current_app.db_conn
        cur = conn.cursor()

        # 近 N 天日志用于关键词统计与趋势
        cur.execute(
            """
            SELECT log_date, keywords, content
            FROM biz_work_log
            WHERE user_id=%s AND log_date >= (CURDATE() - INTERVAL %s DAY)
            ORDER BY log_date ASC
            """,
            (user_id, max(days-1, 0))
        )
        rows = cur.fetchall()

        # 同期与用户相关的事务（任务）：标题与描述纳入关键词统计
        cur.execute(
            """
            SELECT title, description
            FROM biz_task
            WHERE (creator_id=%s OR assigned_id=%s)
              AND (DATE(update_time) >= (CURDATE() - INTERVAL %s DAY))
            ORDER BY update_time DESC
            """,
            (user_id, user_id, max(days-1, 0))
        )
        task_rows = cur.fetchall()

        # 1) 关键词聚合：合并日志 keywords/content 与 任务 title/description
        import re
        word_freq = {}
        def add_text_to_freq(text_str: str):
            for w in re.findall(r"[\u4e00-\u9fa5_a-zA-Z0-9]+", text_str or ''):
                w = w.strip().lower()
                if len(w) <= 1:
                    continue
                word_freq[w] = word_freq.get(w, 0) + 1

        for (log_date, kw, content) in rows:
            add_text_to_freq((kw or ''))
            add_text_to_freq((content or ''))

        for (title, desc) in task_rows:
            add_text_to_freq((title or ''))
            add_text_to_freq((desc or ''))

        # 2) 趋势（按天统计日志条数）
        trend_map = {}
        for (log_date, kw, content) in rows:
            k = log_date.strftime('%Y-%m-%d') if hasattr(log_date, 'strftime') else str(log_date)
            trend_map[k] = trend_map.get(k, 0) + 1

        # 填充缺失天为 0，保证前端连续性
        from datetime import date, timedelta
        today = date.today()
        ordered = []
        for i in range(days):
            d = today - timedelta(days=(days-1-i))
            s = d.strftime('%Y-%m-%d')
            ordered.append({"date": s, "count": int(trend_map.get(s, 0))})

        # 3) 任务分类占比（基于关键词粗分类）
        category_map = {
            '沟通类': ['会议','沟通','同步','讨论','评审','对接'],
            '执行类': ['开发','实现','修复','测试','部署','上线','优化','重构'],
            '规划类': ['规划','计划','设计','方案','评估','调研'],
            '异常处理类': ['异常','故障','告警','回滚','应急','bug']
        }
        category_count = {k: 0 for k in category_map.keys()}
        for w, c in word_freq.items():
            for cat, kws in category_map.items():
                if any(kw.lower() in w for kw in kws):
                    category_count[cat] += c
                    break

        cur.close()
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
        return jsonify({"code": 500, "msg": "服务器内部错误"})