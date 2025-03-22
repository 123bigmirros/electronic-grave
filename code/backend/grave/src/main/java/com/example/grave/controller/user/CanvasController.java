package com.example.grave.controller.user;

import java.util.List;
import java.util.Random;
import java.util.concurrent.CompletableFuture;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.grave.common.context.BaseContext;
import com.example.grave.common.result.Result;
import com.example.grave.pojo.dto.CanvasDTO;
import com.example.grave.pojo.entity.Heritage;
import com.example.grave.pojo.entity.ImageBox;
import com.example.grave.pojo.entity.MarkdownBox;
import com.example.grave.pojo.entity.TextBox;
import com.example.grave.pojo.vo.CanvasVO;
import com.example.grave.service.CanvasService;
import com.fasterxml.jackson.annotation.JsonTypeInfo.None;
import com.example.grave.pojo.entity.HeritageItem;



@CrossOrigin(origins = "http://localhost:1024")
@RestController
@RequestMapping("/user/canvas")
public class CanvasController {
    
    @Autowired
    private CanvasService canvasService;
    @PostMapping("/save")
    public Result submit(@RequestBody CanvasDTO canvasDTO){
        System.out.println("submit");
        // canvasDTO.setId((new Random()).nextLong(10000));
        // System.out.println(canvasDTO.getIsPublic());
        Long userId= BaseContext.getCurrentId();
        if(userId == -1){
            return Result.error("用户未登录");
        }
        canvasDTO.setUserId(userId);
        System.out.println(canvasDTO.getTitle());
        if(canvasDTO.getId() == -1){
            canvasService.saveCanvas(canvasDTO,false);
        }else{
            canvasService.deleteCanvas(canvasDTO.getId(),true);
            canvasService.saveCanvas(canvasDTO, true);
        }
        return Result.success(canvasDTO.getId());
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
        for(HeritageItem item:heritageItems){
            System.out.println(item.getContent());
        }
        return Result.success(heritageItems);
    }

    /**
     * 尝试获取私密遗产内容
     */
    @PostMapping("/heritage/getheritage")
    public CompletableFuture<Result<HeritageItem>> getPrivateHeritage(@RequestParam("heritageId") Long heritageId) {
        long userId = BaseContext.getCurrentId();
        if(userId == -1){
            return CompletableFuture.completedFuture(Result.error("用户未登录"));
        }
        return canvasService.getPrivateHeritageAsync(heritageId)
            .thenApply(heritageItem -> {
                if (heritageItem == null) {
                    return Result.error("很遗憾，您与这份遗产无缘");
                }
                return Result.success(heritageItem);
            });
    }

    @PostMapping("/list")
    public Result<List<CanvasVO>> getCanvasList(){
        long userId = BaseContext.getCurrentId();
        if(userId == -1){
            return Result.error("用户未登录");
        }
        List<CanvasVO> canvasVO = canvasService.getCanvasList(userId);
        return Result.success(canvasVO);
    }

    @GetMapping("/delete/{canvasId}")
    public Result<Void> deleteCanvas(@PathVariable long canvasId) {
        canvasService.deleteCanvas(canvasId,false);
        return Result.success();
    }
    
    @GetMapping("/get/{canvasId}/{needUserId}")
    public Result<CanvasVO> getCanvasById(@PathVariable long canvasId,@PathVariable int needUserId) {
        // System.out.println("getCanvasById");
        
        long userId = BaseContext.getCurrentId();
        if(userId == -1 && needUserId ==1){
            return Result.error("用户未登录");
        }
        else if(needUserId == 0){
            userId = -1;
        }
        CanvasVO canvasVO = canvasService.getCanvasById(userId, canvasId);
        
        for(Heritage heritage:canvasVO.getHeritages()){
            System.out.println(heritage.getId());
            for(HeritageItem item:heritage.getItems()){
                System.out.println(item.getContent());
            }
        }
        return Result.success(canvasVO);
    }
}
