package com.example.grave.pojo.entity;

import java.util.Date;
import java.util.List;

import lombok.Data;

@Data
public class Heritage {
    private Long id;
    private Long pid;          // 用户ID
    private Date publicTime;      // 公开时间
    private int left;  // 图片框的位置
    private int top;
    private int width;
    private int height;
    public void setPosition(Position position) {
        this.left = position.getLeft();
        this.top = position.getTop();
        this.width = position.getWidth();
        this.height = position.getHeight();
    }
    // 非数据库字段，用于存储遗产条目
    private List<HeritageItem> items;
}
