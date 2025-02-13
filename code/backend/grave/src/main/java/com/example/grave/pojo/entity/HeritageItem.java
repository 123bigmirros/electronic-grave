package com.example.grave.pojo.entity;

import lombok.Data;

@Data
public class HeritageItem {
    private Long id;
    private Long heritageId;     // 关联的遗产组件ID
    private String content;       // 遗产内容
    private Boolean isPrivate;    // 是否为"有缘者得"
    private long userId = 0;        // 拥有者ID
} 
