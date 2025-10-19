-- 1️⃣ 删除现有数据库
DROP DATABASE IF EXISTS task_management_system;

-- 2️⃣ 创建数据库
CREATE DATABASE task_management_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE task_management_system;

-- 3️⃣ 设置会话字符集
SET NAMES utf8mb4;

-- 4️⃣ 创建表（先不加外键）

-- 角色表
CREATE TABLE sys_role (
    id INT NOT NULL,
    role_name VARCHAR(255) CHARACTER SET utf8mb4 NOT NULL,
    role_code VARCHAR(64) NOT NULL,
    description VARCHAR(255) CHARACTER SET utf8mb4,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_role_code (role_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 部门表
CREATE TABLE sys_department (
    id INT NOT NULL AUTO_INCREMENT,
    dept_name VARCHAR(255) CHARACTER SET utf8mb4 NOT NULL,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 团队表
CREATE TABLE sys_team (
    id INT NOT NULL AUTO_INCREMENT,
    team_name VARCHAR(255) CHARACTER SET utf8mb4 NOT NULL,
    department_id INT NOT NULL,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_department_id (department_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 用户表
CREATE TABLE sys_user (
    id INT NOT NULL AUTO_INCREMENT,
    username VARCHAR(64) NOT NULL,
    name VARCHAR(64) CHARACTER SET utf8mb4 NOT NULL,
    password VARCHAR(64) NOT NULL,
    mobile VARCHAR(20),
    email VARCHAR(64),
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

-- 任务表
CREATE TABLE biz_task (
    id INT NOT NULL AUTO_INCREMENT,
    parent_id INT,
    title VARCHAR(255) CHARACTER SET utf8mb4 NOT NULL,
    description TEXT CHARACTER SET utf8mb4,
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

-- 工作日志表
CREATE TABLE biz_work_log (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    task_id INT NOT NULL,
    content TEXT CHARACTER SET utf8mb4 NOT NULL,
    keywords TEXT CHARACTER SET utf8mb4,
    log_date DATE NOT NULL,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_user_id (user_id),
    KEY idx_task_id (task_id),
    KEY idx_log_date (log_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- AI分析表
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

-- 5️⃣ 插入角色、部门、团队、用户（示例完整）
INSERT INTO sys_role (id, role_name, role_code, description) VALUES
(1, '部门老总', 'ROLE_BOSS', '部门老总级别'),
(2, '管理员', 'ROLE_ADMIN', '系统管理员'),
(3, '部门经理', 'ROLE_MANAGER', '部门经理级别'),
(4, '团队队长', 'ROLE_LEADER', '团队队长级别'),
(5, '普通员工', 'ROLE_USER', '普通员工级别');

INSERT INTO sys_department (dept_name) VALUES
('技术部'), ('市场部'), ('人事部'), ('产品部');

INSERT INTO sys_team (team_name, department_id) VALUES
('前端开发团队', 1),
('后端开发团队', 1),
('市场推广团队', 2),
('销售团队', 2),
('招聘团队', 3),
('培训团队', 3),
('产品设计团队', 4),
('产品运营团队', 4);

INSERT INTO sys_user (username, name, password, mobile, email, role_id, team_id) VALUES
('admin', '超级管理员', 'admin123', '13800000000', 'admin@company.com', 2, 1),
('tech_boss', '王伟', 'pw123', '13800000001', 'tech_boss@company.com', 1, 1),
('tech_manager', '李娜', 'pw123', '13800000002', 'tech_manager@company.com', 3, 1),
('frontend_leader', '张三', 'pw123', '13800000003', 'frontend_leader@company.com', 4, 1),
('frontend_user1', '赵四', 'pw123', '13800000004', 'frontend1@company.com', 5, 1),
('backend_leader', '钱五', 'pw123', '13800000005', 'backend_leader@company.com', 4, 2),
('backend_user1', '孙六', 'pw123', '13800000006', 'backend1@company.com', 5, 2),
('market_boss', '周总', 'pw123', '13800000007', 'market_boss@company.com', 1, 3),
('market_manager', '吴经理', 'pw123', '13800000008', 'market_manager@company.com', 3, 3),
('promo_leader', '郑七', 'pw123', '13800000009', 'promo_leader@company.com', 4, 3),
('promo_user1', '冯八', 'pw123', '13800000010', 'promo1@company.com', 5, 3),
('sales_leader', '陈九', 'pw123', '13800000011', 'sales_leader@company.com', 4, 4),
('sales_user1', '褚十', 'pw123', '13800000012', 'sales1@company.com', 5, 4),
('hr_boss', '蒋总', 'pw123', '13800000013', 'hr_boss@company.com', 1, 5),
('hr_manager', '沈经理', 'pw123', '13800000014', 'hr_manager@company.com', 3, 5),
('recruit_leader', '韩一', 'pw123', '13800000015', 'recruit_leader@company.com', 4, 5),
('recruit_user1', '杨二', 'pw123', '13800000016', 'recruit1@company.com', 5, 5),
('train_leader', '朱三', 'pw123', '13800000017', 'train_leader@company.com', 4, 6),
('train_user1', '秦四', 'pw123', '13800000018', 'train1@company.com', 5, 6),
('product_boss', '尤总', 'pw123', '13800000019', 'product_boss@company.com', 1, 7),
('product_manager', '许经理', 'pw123', '13800000020', 'product_manager@company.com', 3, 7),
('design_leader', '何五', 'pw123', '13800000021', 'design_leader@company.com', 4, 7),
('design_user1', '吕六', 'pw123', '13800000022', 'design1@company.com', 5, 7),
('operation_leader', '施七', 'pw123', '13800000023', 'operation_leader@company.com', 4, 8),
('operation_user1', '陶八', 'pw123', '13800000024', 'operation1@company.com', 5, 8);

-- 9️⃣ 插入任务示例
INSERT INTO biz_task (parent_id, title, description, creator_id, assigned_id, start_time, end_time, progress, status) VALUES
(NULL, '公司年度项目规划', '制定公司年度技术发展路线图和项目规划', 1, 1, '2024-01-01 09:00:00', '2024-12-31 18:00:00', 30, 'pending'),
(NULL, '技术部季度目标', '技术部本季度重点工作和目标设定', 2, 1, '2024-01-15 09:00:00', '2024-03-31 18:00:00', 60, 'pending'),
(2, '前端架构升级', '将现有前端架构从Vue2升级到Vue3', 2, 1, '2024-02-01 09:00:00', '2024-06-30 18:00:00', 20, 'pending'),
(2, '后端微服务改造', '对现有单体应用进行微服务架构改造', 2, 2, '2024-02-01 09:00:00', '2024-08-31 18:00:00', 15, 'pending'),
(NULL, '个人学习计划', 'React新特性学习和实践', 3, 3, '2024-01-10 09:00:00', '2024-02-29 18:00:00', 80, 'pending');

-- 10️⃣ 插入工作日志示例
INSERT INTO biz_work_log (user_id, task_id, content, keywords, log_date) VALUES
(3, 3, '完成了Vue3基础环境搭建和项目初始化，配置了Vite构建工具', 'Vue3,环境搭建,Vite,配置', '2024-01-15'),
(3, 3, '学习了Composition API的使用，重构了部分组件', 'Vue3,Composition API,组件重构', '2024-01-16'),
(6, 4, '完成了Spring Cloud微服务框架的选型和环境准备', 'Spring Cloud,微服务,框架选型', '2024-01-15'),
(6, 4, '设计了用户服务的微服务拆分方案和API接口', '微服务,API设计,用户服务', '2024-01-16'),
(3, 5, '学习了React Hooks的高级用法和自定义Hooks', 'React,Hooks,自定义Hooks', '2024-01-15');

-- 11️⃣ 插入 AI 分析示例
INSERT INTO biz_ai_analysis (user_id, task_id, keywords, keyword_cloud, task_category_ratio, mbti_summary) VALUES
(3, NULL, 'Vue3,前端开发,组件化,工程化', '{"Vue3": 15, "前端开发": 12, "组件化": 8, "工程化": 6}', '{"前端开发": 60, "学习提升": 30, "技术研究": 10}', 'INTP型人格，擅长技术研究和逻辑分析，在前端开发领域表现出色'),
(6, NULL, '微服务,Spring Cloud,架构设计,后端开发', '{"微服务": 18, "Spring Cloud": 14, "架构设计": 10, "后端开发": 9}', '{"后端开发": 70, "架构设计": 20, "技术研究": 10}', 'ISTJ型人格，注重细节和系统化，适合后端架构设计工作');

-- 12️⃣ 创建索引（保留原有索引）
CREATE INDEX idx_user_task_date ON biz_work_log(user_id, task_id, log_date);
CREATE INDEX idx_task_status_progress ON biz_task(status, progress);
CREATE INDEX idx_user_create_time ON sys_user(create_time);
CREATE INDEX idx_task_create_time ON biz_task(create_time);
CREATE INDEX idx_analysis_user_time ON biz_ai_analysis(user_id, create_time);

-- 13️⃣ 添加外键约束（在数据插入后再加）
ALTER TABLE sys_team ADD FOREIGN KEY (department_id) REFERENCES sys_department(id);
ALTER TABLE sys_user ADD FOREIGN KEY (role_id) REFERENCES sys_role(id);
ALTER TABLE sys_user ADD FOREIGN KEY (team_id) REFERENCES sys_team(id);
ALTER TABLE biz_task ADD FOREIGN KEY (parent_id) REFERENCES biz_task(id) ON DELETE SET NULL;
ALTER TABLE biz_task ADD FOREIGN KEY (creator_id) REFERENCES sys_user(id);
ALTER TABLE biz_work_log ADD FOREIGN KEY (user_id) REFERENCES sys_user(id);
ALTER TABLE biz_work_log ADD FOREIGN KEY (task_id) REFERENCES biz_task(id) ON DELETE CASCADE;
ALTER TABLE biz_ai_analysis ADD FOREIGN KEY (user_id) REFERENCES sys_user(id);
ALTER TABLE biz_ai_analysis ADD FOREIGN KEY (task_id) REFERENCES biz_task(id) ON DELETE SET NULL;

-- 14️⃣ 查看表结构信息
SELECT 
    TABLE_NAME as '表名',
    TABLE_ROWS as '记录数',
    DATA_LENGTH as '数据大小(B)',
    INDEX_LENGTH as '索引大小(B)',
    CREATE_TIME as '创建时间'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'task_management_system';

-- 查看所有表
SHOW TABLES;
