CREATE TABLE biz_task_showcase (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL COMMENT '员工ID',
    task_id INT NOT NULL COMMENT '任务ID',
    sort_order INT NOT NULL DEFAULT 0 COMMENT '前端展示顺序',
    UNIQUE KEY uk_user_task (user_id, task_id)
);