package com.example.grave.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Result;
import org.apache.ibatis.annotations.Results;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.SelectKey;
import org.apache.ibatis.annotations.Update;
import org.apache.ibatis.annotations.Options;

import com.example.grave.pojo.dto.CanvasDTO;
import com.example.grave.pojo.entity.Heritage;
import com.example.grave.pojo.entity.HeritageItem;
import com.example.grave.pojo.entity.ImageBox;
import com.example.grave.pojo.entity.MarkdownBox;
import com.example.grave.pojo.entity.TextBox;
import com.example.grave.pojo.vo.CanvasVO;



public interface CanvasMapper {
    @Insert("INSERT INTO CanvasDTO (uId, title, isPublic) VALUES (#{userId}, #{title}, #{isPublic})")
    @Options(useGeneratedKeys = true, keyProperty = "id", keyColumn = "id")
    public long saveCanvas(CanvasDTO canvasDTO);
    public void insertImageBoxes(CanvasDTO canvasDTO);
    public void insertTextBoxes(CanvasDTO canvasDTO);
    public void insertHeritages(Heritage heritage);
    public void insertHeritageItems(Heritage heritage);
    @Select("SELECT * FROM ImageBox WHERE pid = #{pid}")   
    @Results({
        @Result(property = "left", column = "left_location"),
        @Result(property = "top", column = "top_location"),
        @Result(property = "width", column = "width_location"),
        @Result(property = "height", column = "height_location")
    })
    public List<ImageBox> getImages(long pid);
    @Results({
        @Result(property = "left", column = "left_location"),
        @Result(property = "top", column = "top_location"),
        @Result(property = "width", column = "width_location"),
        @Result(property = "height", column = "height_location")
    })
    @Select("SELECT * FROM TextBox WHERE pid = #{pid}")
    public List<TextBox> getTexts(long pid   ); 
    
    @Select("SELECT * FROM markdown WHERE pid = #{pid}")
    @Results({
        @Result(property = "left", column = "left_location"),
        @Result(property = "top", column = "top_location"),
        @Result(property = "width", column = "width_location"),
        @Result(property = "height", column = "height_location")
    })
    public List<MarkdownBox> getMarkdowns(long pid);
    @Select("SELECT * FROM heritage WHERE pid = #{pid}")
    @Results({
        @Result(property = "left", column = "left_location"),
        @Result(property = "top", column = "top_location"),
        @Result(property = "width", column = "width_location"),
        @Result(property = "height", column = "height_location")
    })
    public List<Heritage> getHeritages(long pid);

    @Select("SELECT * FROM heritage_item WHERE heritage_id = #{heritageId}")
    public List<HeritageItem> getHeritageItems(long heritageId);

    @Select("SELECT * FROM CanvasDTO WHERE isPublic = true ORDER BY RAND() LIMIT 20;")
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

    /**
     * 插入markdown信息
     */
    
    void insertMarkdowns(CanvasDTO canvasDTO);
    

    /**
     * 获取用户画布列表
     */
    @Select("SELECT * FROM CanvasDTO WHERE uId = #{userId}")
    List<CanvasVO> getCanvasList(Long userId);

    /**
     * 删除画布
     */
    @Delete("DELETE FROM CanvasDTO WHERE id = #{canvasId}")
    void deleteCanvas(Long canvasId);

    /**
     * 删除遗产
     */
    @Delete("DELETE FROM heritage WHERE pid = #{canvasId}")
    List<Heritage> deleteHeritages(Long canvasId);

    /**
     * 删除遗产项
     */
    @Delete("DELETE FROM heritage_item WHERE heritage_id = #{heritageId}")
    void deleteHeritageItems(Long heritageId);
    
    /**
     * 删除图片
     */
    @Delete("DELETE FROM ImageBox WHERE pid = #{canvasId}")
    void deleteImages(Long canvasId);

    /**
     * 删除文本
     */
    @Delete("DELETE FROM TextBox WHERE pid = #{canvasId}")
    void deleteTexts(Long canvasId);

    /**
     * 删除markdown
     */
    @Delete("DELETE FROM markdown WHERE pid = #{canvasId}")
    void deleteMarkdowns(Long canvasId);

    /**
     * 获取画布
     */
    @Select("SELECT * FROM CanvasDTO WHERE id = #{canvasId} AND uId = #{userId}")
    CanvasVO getCanvasBy2Id(Long userId, Long canvasId);

    /**
     * 获取画布
     */
    @Results({
        @Result(property = "userId", column = "uId")
    })
    @Select("SELECT * FROM CanvasDTO WHERE id = #{canvasId}")
    CanvasVO getCanvasById(Long canvasId);
}
