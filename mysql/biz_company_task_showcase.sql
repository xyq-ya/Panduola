CREATE TABLE biz_company_task_showcase (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL COMMENT '固定为0代表公司全局',
    task_id INT NOT NULL COMMENT '关联 biz_task.id',
    sort_order INT NOT NULL DEFAULT 0 COMMENT '前端展示顺序',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_task (user_id, task_id),
    KEY idx_task_id (task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 插入外键约束（可选，但推荐）
ALTER TABLE biz_company_task_showcase
ADD CONSTRAINT fk_showcase_task FOREIGN KEY (task_id) REFERENCES biz_task(id) ON DELETE CASCADE;