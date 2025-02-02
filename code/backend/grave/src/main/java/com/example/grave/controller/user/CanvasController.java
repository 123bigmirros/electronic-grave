package com.example.grave.controller.user;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.grave.common.result.Result;
import com.example.grave.pojo.dto.CanvasDTO;
import com.example.grave.pojo.entity.ImageBox;
import com.example.grave.pojo.entity.TextBox;
import com.example.grave.pojo.vo.CanvasVO;
import com.example.grave.service.CanvasService;
import com.fasterxml.jackson.annotation.JsonTypeInfo.None;



@CrossOrigin(origins = "http://localhost:8080")
@RestController
@RequestMapping("/user/canvas")
public class CanvasController {
    
    @Autowired
    private CanvasService canvasService;
    @PostMapping("/save")
    public Result submit(@RequestBody CanvasDTO canvasDTO){
        canvasDTO.setUserId((long) 1);
        for(ImageBox imageBox:canvasDTO.getImages()){
            imageBox.setPid(canvasDTO.getId());
        }
        for(TextBox textBox:canvasDTO.getTexts()){
            textBox.setPid(canvasDTO.getId());
        }
        canvasService.saveCanvas(canvasDTO);
        return Result.success();
    }

    @PostMapping("/get")
    public Result<CanvasVO> getCanvas(int userId,int id){
        CanvasVO canvasVO = canvasService.getCanvas(userId, id);
        return Result.success(canvasVO);
    }

    @GetMapping("/load")
    public Result<List<CanvasVO>> loadCanvas(){
        List<CanvasVO> canvasVO = canvasService.loadCanvas();
        return Result.success(canvasVO);
    }
}
