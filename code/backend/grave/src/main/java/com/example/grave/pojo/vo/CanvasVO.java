package com.example.grave.pojo.vo;

import java.io.Serializable;
import java.util.List;

import com.example.grave.pojo.entity.Heritage;
import com.example.grave.pojo.entity.ImageBox;
import com.example.grave.pojo.entity.TextBox;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CanvasVO implements Serializable {
    private List<ImageBox> images;
    private List<TextBox> texts; 
    private List<Heritage> heritages;
}
