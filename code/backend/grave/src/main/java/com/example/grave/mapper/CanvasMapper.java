package com.example.grave.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import com.example.grave.pojo.dto.CanvasDTO;
import com.example.grave.pojo.entity.ImageBox;
import com.example.grave.pojo.entity.TextBox;



public interface CanvasMapper {
    public void saveCanvas(CanvasDTO canvasDTO);
    
    @Select("SELECT * FROM ImageBox WHERE pid = #{pid}")   
    public List<ImageBox> getImages(long pid);

    @Select("SELECT * FROM TextBox WHERE pid = #{pid}")
    public List<TextBox> getTexts(long pid   ); 
}
