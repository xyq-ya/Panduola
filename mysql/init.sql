-- 删除现有数据库（如果存在）
DROP DATABASE IF EXISTS task_management_system;

-- 创建数据库，指定字符集
CREATE DATABASE task_management_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE task_management_system;

-- 表3-2 角色表（sys_role）
CREATE TABLE sys_role (
    id INT NOT NULL AUTO_INCREMENT,
    role_name VARCHAR(64) NOT NULL,
    role_code VARCHAR(64) NOT NULL,
    description VARCHAR(255),
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_role_code (role_code)
);

-- 表3-3 部门表（sys_department）
CREATE TABLE sys_department (
    id INT NOT NULL AUTO_INCREMENT,
    dept_name VARCHAR(64) NOT NULL,
    parent_id INT,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_parent_id (parent_id)
);

-- 表3-4 团队表（sys_team）
CREATE TABLE sys_team (
    id INT NOT NULL AUTO_INCREMENT,
    team_name VARCHAR(64) NOT NULL,
    department_id INT NOT NULL,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_department_id (department_id)
);

-- 表3-1 用户表（sys_user）
CREATE TABLE sys_user (
    id INT NOT NULL AUTO_INCREMENT,
    username VARCHAR(64) NOT NULL,
    password VARCHAR(64) NOT NULL,
    mobile VARCHAR(20),
    email VARCHAR(64),
    role_id INT NOT NULL,
    department_id INT,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_username (username),
    UNIQUE KEY uk_mobile (mobile),
    UNIQUE KEY uk_email (email),
    KEY idx_role_id (role_id),
    KEY idx_department_id (department_id)
);

-- 表3-5 统一任务表（biz_task）
CREATE TABLE biz_task (
    id INT NOT NULL AUTO_INCREMENT,
    parent_id INT,
    title VARCHAR(128) NOT NULL,
    description TEXT,
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
);

-- 表3-6 工作日志（biz_work_log）
CREATE TABLE biz_work_log (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    task_id INT NOT NULL,
    content TEXT NOT NULL,
    keywords TEXT,
    log_date DATE NOT NULL,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_user_id (user_id),
    KEY idx_task_id (task_id),
    KEY idx_log_date (log_date)
);

-- 表3-7 AI 分析结果表（biz_ai_analysis）
CREATE TABLE biz_ai_analysis (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    task_id INT,
    keywords TEXT,
    keyword_cloud TEXT,
    task_category_ratio TEXT,
    mbti_summary TEXT,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_user_id (user_id),
    KEY idx_task_id (task_id)
);

-- 插入示例数据

-- 插入角色数据
INSERT INTO sys_role (role_name, role_code, description) VALUES
('系统管理员', 'ROLE_ADMIN', '系统管理员，拥有所有权限'),
('部门经理', 'ROLE_MANAGER', '部门经理，管理本部门事务'),
('团队负责人', 'ROLE_LEADER', '团队负责人，管理本团队事务'),
('普通员工', 'ROLE_USER', '普通员工，执行具体任务');

-- 插入部门数据
INSERT INTO sys_department (dept_name, parent_id) VALUES
('总公司', NULL),
('技术部', 1),
('市场部', 1),
('人事部', 1),
('前端开发部', 2),
('后端开发部', 2),
('产品部', 2);

-- 插入团队数据
INSERT INTO sys_team (team_name, department_id) VALUES
('React开发团队', 5),
('Vue开发团队', 5),
('Java开发团队', 6),
('Python开发团队', 6),
('UI设计团队', 7);

-- 插入用户数据
INSERT INTO sys_user (username, password, mobile, email, role_id, department_id) VALUES
('admin', 'admin123', '13800000001', 'admin@company.com', 1, 1),
('tech_manager', 'tech1234', '13800000002', 'tech@company.com', 2, 2),
('market_manager', 'market12', '13800000003', 'market@company.com', 2, 3),
('zhangsan', 'zs123456', '13800000004', 'zhangsan@company.com', 4, 5),
('lisi', 'ls123456', '13800000005', 'lisi@company.com', 4, 6),
('wangwu', 'ww123456', '13800000006', 'wangwu@company.com', 3, 5);

-- 插入任务数据
INSERT INTO biz_task (parent_id, title, description, creator_id, assigned_type, assigned_id, start_time, end_time, progress, status) VALUES
(NULL, '公司年度项目规划', '制定公司年度技术发展路线图和项目规划', 1, 'company', 1, '2024-01-01 09:00:00', '2024-12-31 18:00:00', 30, 'pending'),
(NULL, '技术部季度目标', '技术部本季度重点工作和目标设定', 2, 'department', 2, '2024-01-15 09:00:00', '2024-03-31 18:00:00', 60, 'pending'),
(1, '前端架构升级', '将现有前端架构从Vue2升级到Vue3', 2, 'team', 1, '2024-02-01 09:00:00', '2024-06-30 18:00:00', 20, 'pending'),
(1, '后端微服务改造', '对现有单体应用进行微服务架构改造', 2, 'team', 3, '2024-02-01 09:00:00', '2024-08-31 18:00:00', 15, 'pending'),
(NULL, '个人学习计划', 'React新特性学习和实践', 4, 'personal', 4, '2024-01-10 09:00:00', '2024-02-29 18:00:00', 80, 'pending');

-- 插入工作日志数据
INSERT INTO biz_work_log (user_id, task_id, content, keywords, log_date) VALUES
(4, 3, '完成了Vue3基础环境搭建和项目初始化，配置了Vite构建工具', 'Vue3,环境搭建,Vite,配置', '2024-01-15'),
(4, 3, '学习了Composition API的使用，重构了部分组件', 'Vue3,Composition API,组件重构', '2024-01-16'),
(5, 4, '完成了Spring Cloud微服务框架的选型和环境准备', 'Spring Cloud,微服务,框架选型', '2024-01-15'),
(5, 4, '设计了用户服务的微服务拆分方案和API接口', '微服务,API设计,用户服务', '2024-01-16'),
(4, 5, '学习了React Hooks的高级用法和自定义Hooks', 'React,Hooks,自定义Hooks', '2024-01-15');

-- 插入AI分析结果数据
INSERT INTO biz_ai_analysis (user_id, task_id, keywords, keyword_cloud, task_category_ratio, mbti_summary) VALUES
(4, NULL, 'Vue3,前端开发,组件化,工程化', '{"Vue3": 15, "前端开发": 12, "组件化": 8, "工程化": 6}', '{"前端开发": 60, "学习提升": 30, "技术研究": 10}', 'INTP型人格，擅长技术研究和逻辑分析，在前端开发领域表现出色'),
(5, NULL, '微服务,Spring Cloud,架构设计,后端开发', '{"微服务": 18, "Spring Cloud": 14, "架构设计": 10, "后端开发": 9}', '{"后端开发": 70, "架构设计": 20, "技术研究": 10}', 'ISTJ型人格，注重细节和系统化，适合后端架构设计工作');

-- 创建索引优化查询性能
CREATE INDEX idx_user_task_date ON biz_work_log(user_id, task_id, log_date);
CREATE INDEX idx_task_status_progress ON biz_task(status, progress);
CREATE INDEX idx_user_create_time ON sys_user(create_time);
CREATE INDEX idx_task_create_time ON biz_task(create_time);
CREATE INDEX idx_analysis_user_time ON biz_ai_analysis(user_id, create_time);

-- 现在添加外键约束（在所有数据插入后）
ALTER TABLE sys_department ADD FOREIGN KEY (parent_id) REFERENCES sys_department(id) ON DELETE SET NULL;
ALTER TABLE sys_team ADD FOREIGN KEY (department_id) REFERENCES sys_department(id) ON DELETE CASCADE;
ALTER TABLE sys_user ADD FOREIGN KEY (role_id) REFERENCES sys_role(id);
ALTER TABLE sys_user ADD FOREIGN KEY (department_id) REFERENCES sys_department(id);
ALTER TABLE biz_task ADD FOREIGN KEY (parent_id) REFERENCES biz_task(id) ON DELETE SET NULL;
ALTER TABLE biz_task ADD FOREIGN KEY (creator_id) REFERENCES sys_user(id);
ALTER TABLE biz_work_log ADD FOREIGN KEY (user_id) REFERENCES sys_user(id);
ALTER TABLE biz_work_log ADD FOREIGN KEY (task_id) REFERENCES biz_task(id) ON DELETE CASCADE;
ALTER TABLE biz_ai_analysis ADD FOREIGN KEY (user_id) REFERENCES sys_user(id);
ALTER TABLE biz_ai_analysis ADD FOREIGN KEY (task_id) REFERENCES biz_task(id) ON DELETE SET NULL;

-- 显示表结构信息
SELECT 
    TABLE_NAME as '表名',
    TABLE_ROWS as '记录数',
    DATA_LENGTH as '数据大小(B)',
    INDEX_LENGTH as '索引大小(B)',
    CREATE_TIME as '创建时间'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'task_management_system';

-- 显示所有表的简要信息
SHOW TABLES;