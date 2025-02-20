package com.example.grave.pojo.entity;

import lombok.Data;

@Data
public class MarkdownBox {
    private Long id;
    private Long pid;          // 用户ID
    private String content;    // markdown内容
    private int left;         // 图片框的位置
    private int top;
    private int width;
    private int height;

    public void setPosition(Position position) {
        this.left = position.getLeft();
        this.top = position.getTop();
        this.width = position.getWidth();
        this.height = position.getHeight();
    }
}
