package com.example.grave.service;

import java.util.List;

import com.example.grave.pojo.dto.CanvasDTO;
import com.example.grave.pojo.vo.CanvasVO;
import com.example.grave.pojo.entity.HeritageItem;

public interface CanvasService {

    public void saveCanvas(CanvasDTO canvasDTO);
    public CanvasVO getCanvas(int userId,int id);
    public List<CanvasVO> loadCanvas();

    /**
     * 获取非私密遗产内容
     */
    List<HeritageItem> getNonePrivateHeritage(Long heritageId);

    /**
     * 获取私密遗产内容
     */
    HeritageItem getPrivateHeritage(Long heritageId);
} 
