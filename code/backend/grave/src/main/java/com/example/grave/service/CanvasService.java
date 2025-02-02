package com.example.grave.service;

import java.util.List;

import com.example.grave.pojo.dto.CanvasDTO;
import com.example.grave.pojo.vo.CanvasVO;

public interface CanvasService {

    public void saveCanvas(CanvasDTO canvasDTO);
    public CanvasVO getCanvas(int userId,int id);
    public List<CanvasVO> loadCanvas();
} 
