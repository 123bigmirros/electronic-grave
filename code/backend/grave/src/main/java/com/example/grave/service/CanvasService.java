package com.example.grave.service;

import java.util.List;
import java.util.concurrent.CompletableFuture;

import com.example.grave.pojo.dto.CanvasDTO;
import com.example.grave.pojo.vo.CanvasVO;
import com.example.grave.pojo.entity.HeritageItem;

public interface CanvasService {

    public void saveCanvas(CanvasDTO canvasDTO,boolean justContent);
    public CanvasVO getCanvas(int userId,int id);
    public List<CanvasVO> loadCanvas();

    /**
     * 获取非私密遗产内容
     */
    List<HeritageItem> getNonePrivateHeritage(Long heritageId);

    /**
     * 获取私密遗产内容
     */
    CompletableFuture<HeritageItem> getPrivateHeritageAsync(Long heritageId);

    /**
     * 获取用户画布列表
     */
    List<CanvasVO> getCanvasList(Long userId);

    /**
     * 删除画布
     */
    void deleteCanvas(long canvasId,boolean justContent);

    /**
     * 获取画布
     */
    CanvasVO getCanvasById(long userId,long canvasId);
} 
