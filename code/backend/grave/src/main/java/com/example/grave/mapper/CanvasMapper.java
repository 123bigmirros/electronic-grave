package com.example.grave.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Result;
import org.apache.ibatis.annotations.Results;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import com.example.grave.pojo.dto.CanvasDTO;
import com.example.grave.pojo.entity.Heritage;
import com.example.grave.pojo.entity.HeritageItem;
import com.example.grave.pojo.entity.ImageBox;
import com.example.grave.pojo.entity.TextBox;



public interface CanvasMapper {
    public long saveCanvas(CanvasDTO canvasDTO);
    public void insertImageBoxes(CanvasDTO canvasDTO);
    public void insertTextBoxes(CanvasDTO canvasDTO);
    public void insertHeritages(Heritage heritage);
    public void insertHeritageItems(Heritage heritage);
    @Select("SELECT * FROM ImageBox WHERE pid = #{pid}")   
    public List<ImageBox> getImages(long pid);

    @Select("SELECT * FROM TextBox WHERE pid = #{pid}")
    public List<TextBox> getTexts(long pid   ); 

    @Select("SELECT * FROM heritage WHERE pid = #{pid}")
    public List<Heritage> getHeritages(long pid);

    @Select("SELECT * FROM heritage_item WHERE heritage_id = #{heritageId}")
    public List<HeritageItem> getHeritageItems(long heritageId);

    @Select("SELECT * FROM CanvasDTO ORDER BY RAND() LIMIT 20;")
    @Results({
    @Result(property = "id", column = "id"),
    @Result(property = "userId", column = "uId")
    // 根据需要添加其他字段映射
    })
    public List<CanvasDTO> loadCanvas();

    /**
     * 获取所有遗产项
     */
    @Select("SELECT * FROM heritage_item WHERE heritage_id = #{heritageId}")
    List<HeritageItem> getAllHeritageItemsByHeritageId(Long heritageId);

    /**
     * 根据heritageId获取遗产项
     */


    /**
     * 更新遗产项的拥有者，使用乐观锁确保并发安全
     */
    @Update("UPDATE heritage_item SET user_id = #{userId} " +
            "WHERE id = #{id} AND user_id = 0")
    boolean updateHeritageItemOwner(HeritageItem item);

    /**
     * 获取指定heritage_id下所有未被获得的私密遗产项
     */
    @Select("SELECT * FROM heritage_item WHERE heritage_id = #{heritageId} " +
            "AND is_private = true AND user_id = 0")
    List<HeritageItem> getUnclaimedPrivateHeritageItems(Long heritageId);
}
