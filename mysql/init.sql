DROP DATABASE IF EXISTS task_management_system;

CREATE DATABASE task_management_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE task_management_system;

SET NAMES utf8mb4;

-- ========================================
-- 1. 角色表
-- ========================================
CREATE TABLE sys_role (
    id INT NOT NULL AUTO_INCREMENT,
    role_name VARCHAR(255) CHARACTER SET utf8mb4 NOT NULL,
    role_code VARCHAR(64) NOT NULL,
    description VARCHAR(255) CHARACTER SET utf8mb4,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_role_code (role_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================================
-- 2. 部门表
-- ========================================
CREATE TABLE sys_department (
    id INT NOT NULL AUTO_INCREMENT,
    dept_name VARCHAR(255) CHARACTER SET utf8mb4 NOT NULL,
    manager_id INT NOT NULL,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_manager_id (manager_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================================
-- 3. 团队表
-- ========================================
CREATE TABLE sys_team (
    id INT NOT NULL AUTO_INCREMENT,
    team_name VARCHAR(255) CHARACTER SET utf8mb4 NOT NULL,
    department_id INT NOT NULL,
    leader_id INT NOT NULL,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_department_id (department_id),
    KEY idx_leader_id (leader_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================================
-- 4. 用户表（包含 avatar_url）
-- ========================================
CREATE TABLE sys_user (
    id INT NOT NULL AUTO_INCREMENT,
    username VARCHAR(64) NOT NULL,
    name VARCHAR(64) CHARACTER SET utf8mb4 NOT NULL,
    password VARCHAR(64) NOT NULL,
    mobile VARCHAR(20),
    email VARCHAR(64),
    avatar_url VARCHAR(255) NULL,
    role_id INT NOT NULL,
    team_id INT NOT NULL,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_username (username),
    UNIQUE KEY uk_mobile (mobile),
    UNIQUE KEY uk_email (email),
    KEY idx_role_id (role_id),
    KEY idx_team_id (team_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================================
-- 5. 任务表（包含 image_url）
-- ========================================
CREATE TABLE biz_task (
    id INT NOT NULL AUTO_INCREMENT,
    parent_id INT,
    title VARCHAR(255) CHARACTER SET utf8mb4 NOT NULL,
    description TEXT CHARACTER SET utf8mb4,
    image_url VARCHAR(255) NULL,
    creator_id INT NOT NULL,
    assigned_type VARCHAR(32) NOT NULL DEFAULT 'personal',
    assigned_id INT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    progress INT NOT NULL DEFAULT 0,
    status VARCHAR(32) NOT NULL DEFAULT 'pending',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_parent_id (parent_id),
    KEY idx_creator_id (creator_id),
    KEY idx_assigned_type (assigned_type),
    KEY idx_status (status),
    KEY idx_start_end_time (start_time, end_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================================
-- 6. 工作日志表（包含 image_url）
-- ========================================
CREATE TABLE biz_work_log (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    task_id INT NOT NULL,
    content TEXT CHARACTER SET utf8mb4 NOT NULL,
    keywords TEXT CHARACTER SET utf8mb4,
    image_url VARCHAR(255) NULL,
    log_date DATE NOT NULL,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_user_id (user_id),
    KEY idx_task_id (task_id),
    KEY idx_log_date (log_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================================
-- 7. AI 分析表
-- ========================================
CREATE TABLE biz_ai_analysis (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    task_id INT,
    keywords TEXT CHARACTER SET utf8mb4,
    keyword_cloud TEXT CHARACTER SET utf8mb4,
    task_category_ratio TEXT CHARACTER SET utf8mb4,
    mbti_summary TEXT CHARACTER SET utf8mb4,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_user_id (user_id),
    KEY idx_task_id (task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================================
-- 8. 插入角色（固定 id 避免混乱）
-- ========================================
INSERT INTO sys_role (id, role_name, role_code, description) VALUES
(1, '部门老总', 'ROLE_BOSS', '部门老总级别'),
(2, '管理员', 'ROLE_ADMIN', '系统管理员'),
(3, '部门经理', 'ROLE_MANAGER', '部门经理级别'),
(4, '团队队长', 'ROLE_LEADER', '团队队长级别'),
(5, '普通员工', 'ROLE_USER', '普通员工级别');

-- ========================================
-- 9. 插入 admin（id=1）作为占位 manager/leader（team_id 先填 0，稍后更新）
-- 这样可以在不使用占位 dummy 的情况下保证 manager_id/leader_id 有有效引用
-- ========================================
INSERT INTO sys_user (id, username, name, password, mobile, email, avatar_url, role_id, team_id)
VALUES (1, 'admin', '超级管理员', 'admin123', '13800000000', 'admin@company.com', 'https://i.pravatar.cc/150?img=1', 2, 0);

-- ========================================
-- 10. 插入部门（引用 manager_id = 1）
-- ========================================
INSERT INTO sys_department (dept_name, manager_id)
VALUES
('技术部', 1), ('市场部', 1), ('人事部', 1), ('产品部', 1);

-- ========================================
-- 11. 插入团队（leader_id = 1）
-- ========================================
INSERT INTO sys_team (team_name, department_id, leader_id)
VALUES
('前端开发团队', (SELECT id FROM sys_department WHERE dept_name='技术部'), 1),
('后端开发团队', (SELECT id FROM sys_department WHERE dept_name='技术部'), 1),
('算法与AI组', (SELECT id FROM sys_department WHERE dept_name='技术部'), 1),
('市场推广团队', (SELECT id FROM sys_department WHERE dept_name='市场部'), 1),
('销售团队', (SELECT id FROM sys_department WHERE dept_name='市场部'), 1),
('产品项目组', (SELECT id FROM sys_department WHERE dept_name='产品部'), 1),
('人事事务组', (SELECT id FROM sys_department WHERE dept_name='人事部'), 1),
('系统管理团队', (SELECT id FROM sys_department WHERE dept_name='技术部'), 1);

-- ========================================
-- 12. 插入更多用户（示例数据，全部有 team_id）
-- ========================================
-- 部门经理
INSERT INTO sys_user (username, name, password, mobile, email, avatar_url, role_id, team_id)
VALUES
('tech_manager', '李娜', 'pw123', '13800000002', 'tech_manager@company.com', 'https://i.pravatar.cc/150?img=2', 3,
 (SELECT id FROM sys_team WHERE team_name='前端开发团队')),
('market_manager', '吴经理', 'pw123', '13800000008', 'market_manager@company.com', 'https://i.pravatar.cc/150?img=3', 3,
 (SELECT id FROM sys_team WHERE team_name='市场推广团队')),
('hr_manager', '王芳', 'pw123', '13800000020', 'hr_manager@company.com', 'https://i.pravatar.cc/150?img=4', 3,
 (SELECT id FROM sys_team WHERE team_name='人事事务组')),
('product_manager', '刘伟', 'pw123', '13800000021', 'product_manager@company.com', 'https://i.pravatar.cc/150?img=5', 3,
 (SELECT id FROM sys_team WHERE team_name='产品项目组'));

-- 团队长
INSERT INTO sys_user (username, name, password, mobile, email, avatar_url, role_id, team_id)
VALUES
('frontend_leader', '张三', 'pw123', '13800000003', 'frontend_leader@company.com', 'https://i.pravatar.cc/150?img=6', 4,
 (SELECT id FROM sys_team WHERE team_name='前端开发团队')),
('backend_leader', '钱五', 'pw123', '13800000005', 'backend_leader@company.com', 'https://i.pravatar.cc/150?img=7', 4,
 (SELECT id FROM sys_team WHERE team_name='后端开发团队')),
('ai_leader', '赵明', 'pw123', '13800000013', 'ai_leader@company.com', 'https://i.pravatar.cc/150?img=8', 4,
 (SELECT id FROM sys_team WHERE team_name='算法与AI组')),
('promo_leader', '郑七', 'pw123', '13800000009', 'promo_leader@company.com', 'https://i.pravatar.cc/150?img=9', 4,
 (SELECT id FROM sys_team WHERE team_name='市场推广团队')),
('sales_leader', '陈九', 'pw123', '13800000011', 'sales_leader@company.com', 'https://i.pravatar.cc/150?img=10', 4,
 (SELECT id FROM sys_team WHERE team_name='销售团队'));

-- 普通员工（多个示例）
INSERT INTO sys_user (username, name, password, mobile, email, avatar_url, role_id, team_id)
VALUES
('frontend_user1', '赵四', 'pw123', '13800000004', 'frontend1@company.com', 'https://i.pravatar.cc/150?img=11', 5,
 (SELECT id FROM sys_team WHERE team_name='前端开发团队')),
('frontend_user2', '周燕', 'pw123', '13800000014', 'frontend2@company.com', 'https://i.pravatar.cc/150?img=12', 5,
 (SELECT id FROM sys_team WHERE team_name='前端开发团队')),
('backend_user1', '孙六', 'pw123', '13800000006', 'backend1@company.com', 'https://i.pravatar.cc/150?img=13', 5,
 (SELECT id FROM sys_team WHERE team_name='后端开发团队')),
('backend_user2', '钱康', 'pw123', '13800000015', 'backend2@company.com', 'https://i.pravatar.cc/150?img=14', 5,
 (SELECT id FROM sys_team WHERE team_name='后端开发团队')),
('ai_engineer1', '顾兰', 'pw123', '13800000016', 'aieng1@company.com', 'https://i.pravatar.cc/150?img=15', 5,
 (SELECT id FROM sys_team WHERE team_name='算法与AI组')),
('promo_user1', '冯八', 'pw123', '13800000010', 'promo1@company.com', 'https://i.pravatar.cc/150?img=17', 5,
 (SELECT id FROM sys_team WHERE team_name='市场推广团队')),
('sales_user1', '褚十', 'pw123', '13800000012', 'sales1@company.com', 'https://i.pravatar.cc/150?img=18', 5,
 (SELECT id FROM sys_team WHERE team_name='销售团队')),
('hr_staff1', '孙霞', 'pw123', '13800000017', 'hr1@company.com', 'https://i.pravatar.cc/150?img=19', 5,
 (SELECT id FROM sys_team WHERE team_name='人事事务组'));

-- ========================================
-- 13. 更新 admin 的 team_id 为 系统管理团队（之前是 0）
-- ========================================
UPDATE sys_user
SET team_id = (SELECT id FROM sys_team WHERE team_name='系统管理团队')
WHERE id = 1;

-- ========================================
-- 14. 插入任务示例（带 image_url）
-- ========================================
INSERT INTO biz_task (parent_id, title, description, image_url, creator_id, assigned_type, assigned_id, start_time, end_time, progress, status)
VALUES
(NULL, '开发登录模块', '完成前端登录界面和后端接口', 'https://picsum.photos/seed/login/400/200', (SELECT id FROM sys_user WHERE username='tech_manager'), 'team', (SELECT id FROM sys_team WHERE team_name='前端开发团队'), '2025-11-01 09:00:00', '2025-11-10 18:00:00', 50, 'in_progress'),
(NULL, '开发注册模块', '实现注册功能及表单验证', 'https://picsum.photos/seed/register/400/200', (SELECT id FROM sys_user WHERE username='tech_manager'), 'team', (SELECT id FROM sys_team WHERE team_name='前端开发团队'), '2025-11-02 09:00:00', '2025-11-12 18:00:00', 20, 'pending'),
(NULL, '后端API设计', '设计用户管理相关API', 'https://picsum.photos/seed/api/400/200', (SELECT id FROM sys_user WHERE username='tech_manager'), 'team', (SELECT id FROM sys_team WHERE team_name='后端开发团队'), '2025-11-01 09:00:00', '2025-11-15 18:00:00', 30, 'in_progress'),
(NULL, '市场推广方案', '策划双十一活动推广方案', 'https://picsum.photos/seed/market/400/200', (SELECT id FROM sys_user WHERE username='market_manager'), 'team', (SELECT id FROM sys_team WHERE team_name='市场推广团队'), '2025-11-05 09:00:00', '2025-11-20 18:00:00', 10, 'pending'),
(NULL, '销售数据分析', '分析上季度销售数据，生成报表', 'https://picsum.photos/seed/sales/400/200', (SELECT id FROM sys_user WHERE username='market_manager'), 'team', (SELECT id FROM sys_team WHERE team_name='销售团队'), '2025-11-03 09:00:00', '2025-11-12 18:00:00', 0, 'pending'),
((SELECT id FROM biz_task WHERE title='开发登录模块'), '登录模块单元测试', '编写并通过登录模块单元测试', NULL, (SELECT id FROM sys_user WHERE username='frontend_leader'), 'personal', (SELECT id FROM sys_user WHERE username='frontend_user1'), '2025-11-03 09:00:00', '2025-11-06 18:00:00', 70, 'in_progress');

-- ========================================
-- 15. 插入工作日志示例（带 image_url）
-- ========================================
INSERT INTO biz_work_log (user_id, task_id, content, keywords, image_url, log_date)
VALUES
((SELECT id FROM sys_user WHERE username='frontend_user1'), (SELECT id FROM biz_task WHERE title='开发登录模块'), '完成登录页框架搭建，样式待调整', '登录,前端,样式', 'https://picsum.photos/seed/log1/200/120', '2025-11-02'),
((SELECT id FROM sys_user WHERE username='frontend_user2'), (SELECT id FROM biz_task WHERE title='开发登录模块'), '修复按钮点击事件与表单验证', '表单,验证,bug', 'https://picsum.photos/seed/log2/200/120', '2025-11-03'),
((SELECT id FROM sys_user WHERE username='backend_user1'), (SELECT id FROM biz_task WHERE title='后端API设计'), '完成用户登录接口初稿，返回 token', '后端,API,登录', NULL, '2025-11-04'),
((SELECT id FROM sys_user WHERE username='ai_engineer1'), (SELECT id FROM biz_task WHERE title='后端API设计'), '准备数据集并开始模型训练', 'AI,训练,数据', 'https://picsum.photos/seed/log4/200/120', '2025-11-05'),
((SELECT id FROM sys_user WHERE username='market_manager'), (SELECT id FROM biz_task WHERE title='市场推广方案'), '完成渠道分析部分', '市场,渠道,分析', NULL, '2025-11-06');

-- ========================================
-- 16. 插入 AI 分析示例（关联日志）
-- ========================================
INSERT INTO biz_ai_analysis (user_id, task_id, keywords, keyword_cloud, task_category_ratio, mbti_summary)
VALUES
((SELECT id FROM sys_user WHERE username='ai_engineer1'), (SELECT id FROM biz_task WHERE title='后端API设计'), '模型,训练,数据', '模型,训练,数据', '{"research":0.6,"development":0.4}', 'ENTJ-偏工程'),
((SELECT id FROM sys_user WHERE username='frontend_user1'), (SELECT id FROM biz_task WHERE title='开发登录模块'), '前端,样式,表单', '前端,样式,表单', '{"development":0.9,"testing":0.1}', 'ISFJ-注重细节');

-- ========================================
-- 17. 添加外键约束（最后添加，确保所有引用存在）
-- ========================================
-- sys_user.role_id -> sys_role.id
ALTER TABLE sys_user
ADD CONSTRAINT fk_user_role FOREIGN KEY (role_id) REFERENCES sys_role(id);

-- sys_user.team_id -> sys_team.id
ALTER TABLE sys_user
ADD CONSTRAINT fk_user_team FOREIGN KEY (team_id) REFERENCES sys_team(id);

-- sys_department.manager_id -> sys_user.id
ALTER TABLE sys_department
ADD CONSTRAINT fk_dept_manager FOREIGN KEY (manager_id) REFERENCES sys_user(id);

-- sys_team.department_id -> sys_department.id
ALTER TABLE sys_team
ADD CONSTRAINT fk_team_dept FOREIGN KEY (department_id) REFERENCES sys_department(id);

-- sys_team.leader_id -> sys_user.id
ALTER TABLE sys_team
ADD CONSTRAINT fk_team_leader FOREIGN KEY (leader_id) REFERENCES sys_user(id);

-- biz_task.parent_id -> biz_task.id
ALTER TABLE biz_task
ADD CONSTRAINT fk_task_parent FOREIGN KEY (parent_id) REFERENCES biz_task(id) ON DELETE SET NULL;

-- biz_task.creator_id -> sys_user.id
ALTER TABLE biz_task
ADD CONSTRAINT fk_task_creator FOREIGN KEY (creator_id) REFERENCES sys_user(id);

-- biz_work_log.user_id -> sys_user.id
ALTER TABLE biz_work_log
ADD CONSTRAINT fk_log_user FOREIGN KEY (user_id) REFERENCES sys_user(id);

-- biz_work_log.task_id -> biz_task.id
ALTER TABLE biz_work_log
ADD CONSTRAINT fk_log_task FOREIGN KEY (task_id) REFERENCES biz_task(id) ON DELETE CASCADE;

-- biz_ai_analysis.user_id -> sys_user.id
ALTER TABLE biz_ai_analysis
ADD CONSTRAINT fk_ai_user FOREIGN KEY (user_id) REFERENCES sys_user(id);

-- biz_ai_analysis.task_id -> biz_task.id
ALTER TABLE biz_ai_analysis
ADD CONSTRAINT fk_ai_task FOREIGN KEY (task_id) REFERENCES biz_task(id) ON DELETE SET NULL;

-- ========================================
-- 18. 校验：显示所有表与部分数据
-- ========================================
SHOW TABLES;

-- 一些查询验证（可选）
SELECT id, username, name, role_id, team_id FROM sys_user ORDER BY id;
SELECT id, dept_name, manager_id FROM sys_department;
SELECT id, team_name, department_id, leader_id FROM sys_team;
SELECT id, title, creator_id, assigned_type, assigned_id FROM biz_task;
SELECT id, user_id, task_id, log_date, image_url FROM biz_work_log;

-- ========================================
-- 完成
-- ========================================
-- 更多部门经理
INSERT INTO sys_user (username, name, password, mobile, email, role_id, team_id)
VALUES
('tech_manager2', '周亮', 'pw123', '13800000022', 'tech_manager2@company.com', 3,
 (SELECT id FROM sys_team WHERE team_name='系统管理团队')),
('market_manager2', '蒋峰', 'pw123', '13800000023', 'market_manager2@company.com', 3,
 (SELECT id FROM sys_team WHERE team_name='市场推广团队')),
('hr_manager2', '邱敏', 'pw123', '13800000024', 'hr_manager2@company.com', 3,
 (SELECT id FROM sys_team WHERE team_name='系统管理团队')),
('product_manager2', '龚宇', 'pw123', '13800000025', 'product_manager2@company.com', 3,
 (SELECT id FROM sys_team WHERE team_name='系统管理团队'));

-- 更多团队长
INSERT INTO sys_user (username, name, password, mobile, email, role_id, team_id)
VALUES
('frontend_leader2', '杨明', 'pw123', '13800000026', 'frontend_leader2@company.com', 4,
 (SELECT id FROM sys_team WHERE team_name='前端开发团队')),
('backend_leader2', '马军', 'pw123', '13800000027', 'backend_leader2@company.com', 4,
 (SELECT id FROM sys_team WHERE team_name='后端开发团队')),
('promo_leader2', '许静', 'pw123', '13800000028', 'promo_leader2@company.com', 4,
 (SELECT id FROM sys_team WHERE team_name='市场推广团队')),
('sales_leader2', '白超', 'pw123', '13800000029', 'sales_leader2@company.com', 4,
 (SELECT id FROM sys_team WHERE team_name='销售团队'));
-- ========================================
-- 修正所有部门的部门经理（manager_id）
-- ========================================
UPDATE sys_department SET manager_id = (SELECT id FROM sys_user WHERE username='tech_manager')
WHERE dept_name = '技术部';

UPDATE sys_department SET manager_id = (SELECT id FROM sys_user WHERE username='market_manager')
WHERE dept_name = '市场部';

UPDATE sys_department SET manager_id = (SELECT id FROM sys_user WHERE username='hr_manager')
WHERE dept_name = '人事部';

UPDATE sys_department SET manager_id = (SELECT id FROM sys_user WHERE username='product_manager')
WHERE dept_name = '产品部';


-- ========================================
-- 修正所有团队的团队领导（leader_id）
-- ========================================
UPDATE sys_team SET leader_id = (SELECT id FROM sys_user WHERE username='frontend_leader')
WHERE team_name='前端开发团队';

UPDATE sys_team SET leader_id = (SELECT id FROM sys_user WHERE username='backend_leader')
WHERE team_name='后端开发团队';

UPDATE sys_team SET leader_id = (SELECT id FROM sys_user WHERE username='ai_leader')
WHERE team_name='算法与AI组';

UPDATE sys_team SET leader_id = (SELECT id FROM sys_user WHERE username='promo_leader')
WHERE team_name='市场推广团队';

UPDATE sys_team SET leader_id = (SELECT id FROM sys_user WHERE username='sales_leader')
WHERE team_name='销售团队';

UPDATE sys_team SET leader_id = (SELECT id FROM sys_user WHERE username='product_manager')
WHERE team_name='产品项目组';

UPDATE sys_team SET leader_id = (SELECT id FROM sys_user WHERE username='hr_manager')
WHERE team_name='人事事务组';

-- 系统管理团队（你可以换掉 admin）
UPDATE sys_team SET leader_id = (SELECT id FROM sys_user WHERE username='admin')
WHERE team_name='系统管理团队';
-- ========================================
-- 插入父任务（总任务）
-- ========================================
SET @creator := (SELECT id FROM sys_user WHERE username='tech_manager');
SET @dept_id := (SELECT id FROM sys_department WHERE dept_name='技术部');

INSERT INTO biz_task (
    parent_id, title, description, creator_id,
    assigned_type, assigned_id,
    start_time, end_time, progress, status
)
VALUES (
    NULL,
    '新系统开发项目（总任务）',
    '从零搭建企业内部任务管理系统。',
    @creator,
    'department',
    @dept_id,
    '2025-12-01 09:00:00',
    '2026-01-30 18:00:00',
    0,
    'pending'
);

-- 取出父任务 ID（避免 1093）
SET @root_task_id := (SELECT id FROM biz_task WHERE title='新系统开发项目（总任务）' LIMIT 1);


-- ========================================
-- 1. 前端框架搭建
-- ========================================
SET @team_fe := (SELECT id FROM sys_team WHERE team_name='前端开发团队');

INSERT INTO biz_task (
    parent_id, title, description, creator_id,
    assigned_type, assigned_id,
    start_time, end_time, progress, status
)
VALUES (
    @root_task_id,
    '前端框架搭建',
    '搭建整体前端框架与页面结构。',
    @creator,
    'team',
    @team_fe,
    '2025-12-02 09:00:00',
    '2025-12-15 18:00:00',
    0,
    'pending'
);


-- ========================================
-- 2. 后端框架搭建
-- ========================================
SET @team_be := (SELECT id FROM sys_team WHERE team_name='后端开发团队');

INSERT INTO biz_task (
    parent_id, title, description, creator_id,
    assigned_type, assigned_id,
    start_time, end_time, progress, status
)
VALUES (
    @root_task_id,
    '后端服务框架搭建',
    '后端主服务结构搭建与接口标准确定。',
    @creator,
    'team',
    @team_be,
    '2025-12-02 09:00:00',
    '2025-12-20 18:00:00',
    0,
    'pending'
);


-- ========================================
-- 3. 登录模块开发（个人任务）
-- ========================================
SET @leader_fe := (SELECT id FROM sys_user WHERE username='frontend_leader');
SET @fe_user1 := (SELECT id FROM sys_user WHERE username='frontend_user1');

INSERT INTO biz_task (
    parent_id, title, description, creator_id,
    assigned_type, assigned_id,
    start_time, end_time, progress, status
)
VALUES (
    @root_task_id,
    '登录模块开发',
    '负责登录页、表单验证与 API 对接。',
    @leader_fe,
    'personal',
    @fe_user1,
    '2025-12-03 09:00:00',
    '2025-12-08 18:00:00',
    0,
    'pending'
);

-- 获取登录模块 ID（不再直接 select 触发 1093）
SET @login_task_id := (SELECT id FROM biz_task WHERE title='登录模块开发' LIMIT 1);


-- ========================================
-- 4. 子任务：登录模块单元测试
-- ========================================
SET @fe_user2 := (SELECT id FROM sys_user WHERE username='frontend_user2');

INSERT INTO biz_task (
    parent_id, title, description, creator_id,
    assigned_type, assigned_id,
    start_time, end_time, progress, status
)
VALUES (
    @login_task_id,
    '登录模块单元测试',
    '编写并测试登录模块单元测试用例。',
    @leader_fe,
    'personal',
    @fe_user2,
    '2025-12-05 09:00:00',
    '2025-12-06 18:00:00',
    0,
    'pending'
);
ALTER TABLE biz_work_log
ADD COLUMN latitude DOUBLE NULL COMMENT '纬度',
ADD COLUMN longitude DOUBLE NULL COMMENT '经度';