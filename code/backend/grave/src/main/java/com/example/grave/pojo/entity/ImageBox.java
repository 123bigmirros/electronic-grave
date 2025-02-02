package com.example.grave.pojo.entity;

import lombok.Data;

@Data
public class ImageBox{
    private Long id;
    private Long pid;
    private String imageUrl;  // 图片框的图片 URL

    private int left;  // 图片框的位置
    private int top;
    private int width;
    private int height;
}