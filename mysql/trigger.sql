CREATE TABLE biz_message (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    task_id INT NULL,
    content TEXT CHARACTER SET utf8mb4 NOT NULL,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_user_id (user_id),
    KEY idx_task_id (task_id),
    KEY idx_is_read (is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 外键约束
ALTER TABLE biz_message
ADD CONSTRAINT fk_message_user FOREIGN KEY (user_id) REFERENCES sys_user(id),
ADD CONSTRAINT fk_message_task FOREIGN KEY (task_id) REFERENCES biz_task(id) ON DELETE SET NULL;