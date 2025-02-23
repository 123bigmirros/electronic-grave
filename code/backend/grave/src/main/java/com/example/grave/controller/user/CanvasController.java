package com.example.grave.controller.user;

import java.util.List;
import java.util.Random;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.grave.common.context.BaseContext;
import com.example.grave.common.result.Result;
import com.example.grave.pojo.dto.CanvasDTO;
import com.example.grave.pojo.entity.Heritage;
import com.example.grave.pojo.entity.ImageBox;
import com.example.grave.pojo.entity.TextBox;
import com.example.grave.pojo.vo.CanvasVO;
import com.example.grave.service.CanvasService;
import com.fasterxml.jackson.annotation.JsonTypeInfo.None;
import com.example.grave.pojo.entity.HeritageItem;



// @CrossOrigin(origins = "http://localhost:8080")
@RestController
@RequestMapping("/user/canvas")
public class CanvasController {
    
    @Autowired
    private CanvasService canvasService;
    @PostMapping("/save")
    public Result submit(@RequestBody CanvasDTO canvasDTO){
        // canvasDTO.setId((new Random()).nextLong(10000));
        Long userId= BaseContext.getCurrentId();
        if(userId == -1){
            return Result.error("用户未登录");
        }
        canvasDTO.setUserId(userId);
        
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

    /**
     * 获取非私密遗产内容
     */
    @GetMapping("/heritage/NonePrivateHeritage")
    public Result<List<HeritageItem>> getNonePrivateHeritage(Long heritageId) {
        List<HeritageItem> heritageItems = canvasService.getNonePrivateHeritage(heritageId);
        return Result.success(heritageItems);
    }

    /**
     * 尝试获取私密遗产内容
     */
    @PostMapping("/heritage/getheritage")
    public Result<HeritageItem> getPrivateHeritage(@RequestBody HeritageItem request) {
        HeritageItem heritageItem = canvasService.getPrivateHeritage(request.getHeritageId());
        return Result.success(heritageItem);
    }
}
