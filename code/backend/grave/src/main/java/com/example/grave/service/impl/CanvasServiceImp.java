package com.example.grave.service.impl;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.example.grave.mapper.CanvasMapper;
import com.example.grave.pojo.dto.CanvasDTO;
import com.example.grave.pojo.vo.CanvasVO;
import com.example.grave.service.CanvasService;

@Service
public class CanvasServiceImp implements CanvasService {
    @Autowired
    private CanvasMapper canvasMapper;

    
    public void saveCanvas(CanvasDTO canvasDTO) {
        canvasMapper.saveCanvas(canvasDTO);
    }


    @Override
    public CanvasVO getCanvas(int userId, int id) {
        CanvasVO canvasVO = new CanvasVO();
        canvasVO.setImages(canvasMapper.getImages(id));;
        canvasVO.setTexts(canvasMapper.getTexts(id));
        return canvasVO;
    }
    
}
