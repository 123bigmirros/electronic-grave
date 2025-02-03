package com.example.grave.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Result;
import org.apache.ibatis.annotations.Results;
import org.apache.ibatis.annotations.Select;

import com.example.grave.pojo.dto.CanvasDTO;
import com.example.grave.pojo.entity.ImageBox;
import com.example.grave.pojo.entity.TextBox;



public interface CanvasMapper {
    public void saveCanvas(CanvasDTO canvasDTO);
    public void insertImageBoxes(CanvasDTO canvasDTO);
    public void insertTextBoxes(CanvasDTO canvasDTO);
    @Select("SELECT * FROM ImageBox WHERE pid = #{pid}")   
    public List<ImageBox> getImages(long pid);

    @Select("SELECT * FROM TextBox WHERE pid = #{pid}")
    public List<TextBox> getTexts(long pid   ); 

    @Select("SELECT * FROM CanvasDTO ORDER BY RAND() LIMIT 10;")
    @Results({
    @Result(property = "id", column = "id"),
    @Result(property = "userId", column = "uId")
    // 根据需要添加其他字段映射
    })
    public List<CanvasDTO> loadCanvas();
}
