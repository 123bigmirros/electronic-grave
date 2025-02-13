package com.example.grave.pojo.entity;

import java.util.Date;
import java.util.List;

import lombok.Data;

@Data
public class Heritage {
    private Long id;
    private Long pid;          // 用户ID
    private Date publicTime;      // 公开时间
    private Position position;
    
    // 非数据库字段，用于存储遗产条目
    private List<HeritageItem> items;
}
