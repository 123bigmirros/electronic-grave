package com.example.grave.pojo.entity;

import lombok.Data;

@Data
public class TextBox {
    private Long id;
    private Long pid;
    private String content;  

    private int left;  
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
