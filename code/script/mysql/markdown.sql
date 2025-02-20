CREATE TABLE markdown (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    pid BIGINT NOT NULL COMMENT '用户ID',
    content TEXT COMMENT 'markdown内容',
    left_location INT,                 -- Left position of the text box
    top_location INT,                  -- Top position of the text box
    width_location INT,                -- Width of the text box
    height_location INT               -- Height of the text box

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Markdown组件表';

