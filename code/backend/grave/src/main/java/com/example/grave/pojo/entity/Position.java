package com.example.grave.pojo.entity;

import lombok.Data;

@Data
public class Position {
    private int left;  // 图片框的位置
    private int top;
    private int width;
    private int height;
}
