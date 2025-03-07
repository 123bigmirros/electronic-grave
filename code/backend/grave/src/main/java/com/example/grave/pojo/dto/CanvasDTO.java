package com.example.grave.pojo.dto;

import java.util.List;

import com.example.grave.pojo.entity.Heritage;
import com.example.grave.pojo.entity.ImageBox;
import com.example.grave.pojo.entity.MarkdownBox;
import com.example.grave.pojo.entity.TextBox;

import lombok.Data;

@Data
public class CanvasDTO {
    private long id;
    private long userId;
    private String title;
    private int isPublic;
    private List<ImageBox> images;
    private List<TextBox> texts;
    private List<Heritage> heritages;
    private List<MarkdownBox> markdowns;
}
