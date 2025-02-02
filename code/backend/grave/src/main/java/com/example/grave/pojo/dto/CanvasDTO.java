package com.example.grave.pojo.dto;

import java.util.List;

import com.example.grave.pojo.entity.ImageBox;
import com.example.grave.pojo.entity.TextBox;

import lombok.Data;

@Data
public class CanvasDTO {
    private long id;
    private long userId;
    private List<ImageBox> images;
    private List<TextBox> texts;
}
