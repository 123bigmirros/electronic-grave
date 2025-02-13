-- 创建遗产组件表
CREATE TABLE heritage (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    public_time DATETIME COMMENT '公开时间',
    left_location INT,                 -- Left position of the text box
    top_location INT,                  -- Top position of the text box
    width_location INT,                -- Width of the text box
    height_location INT ,            -- Height of the text box
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='遗产组件表';

-- 创建遗产条目表
CREATE TABLE heritage_item (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    heritage_id BIGINT NOT NULL COMMENT '关联的遗产组件ID',
    content TEXT NOT NULL COMMENT '遗产内容',
    is_private BOOLEAN NOT NULL DEFAULT FALSE COMMENT '是否为"有缘者得"',
    INDEX idx_heritage_id (heritage_id),
    FOREIGN KEY (heritage_id) REFERENCES heritage(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='遗产条目表';
