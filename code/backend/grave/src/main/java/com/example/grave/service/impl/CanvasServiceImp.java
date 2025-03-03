package com.example.grave.service.impl;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;

import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import com.example.grave.common.context.BaseContext;
import com.example.grave.mapper.CanvasMapper;
import com.example.grave.pojo.dto.CanvasDTO;
import com.example.grave.pojo.entity.Heritage;
import com.example.grave.pojo.entity.HeritageItem;
import com.example.grave.pojo.entity.ImageBox;
import com.example.grave.pojo.entity.MarkdownBox;
import com.example.grave.pojo.entity.TextBox;
import com.example.grave.pojo.vo.CanvasVO;
import com.example.grave.service.CanvasService;
import com.example.grave.pojo.entity.HeritageRequest;

@Service
public class CanvasServiceImp implements CanvasService {
    @Autowired
    private CanvasMapper canvasMapper;

    @Autowired
    private KafkaTemplate<String, HeritageRequest> kafkaTemplate;
    
    @Value("${kafka.topics.heritage-requests}")
    private String heritageRequestsTopic;
    
    // 使用ConcurrentMap存储处理中的请求结果
    private ConcurrentMap<String, HeritageItem> requestResults = new ConcurrentHashMap<>();

    // 存储进行中的请求和对应的CompletableFuture
    private ConcurrentMap<String, CompletableFuture<HeritageItem>> pendingRequests = new ConcurrentHashMap<>();

    public void saveCanvas(CanvasDTO canvasDTO,boolean justContent) {
        // 保存画布主信息并获取生成的ID
        if(!justContent){
            canvasMapper.saveCanvas(canvasDTO);
        }
        // System.out.println("ocao");
        // System.out.println(canvasDTO.getId());

        
        // 保存图片盒子
        if (canvasDTO.getImages() != null && !canvasDTO.getImages().isEmpty()) {
            canvasMapper.insertImageBoxes(canvasDTO);
        }
        
        // 保存文本盒子
        if (canvasDTO.getTexts() != null && !canvasDTO.getTexts().isEmpty()) {
            canvasMapper.insertTextBoxes(canvasDTO);
        }
        
        // 保存遗产信息
        if (canvasDTO.getHeritages() != null && !canvasDTO.getHeritages().isEmpty()) {
            for(Heritage heritage:canvasDTO.getHeritages()){
                heritage.setPid(canvasDTO.getId());
                canvasMapper.insertHeritages(heritage);
                if (heritage.getItems() != null && !heritage.getItems().isEmpty()) {
                    canvasMapper.insertHeritageItems(heritage);
                }
            }
        }
        // 保存markdown信息
        if (canvasDTO.getMarkdowns() != null && !canvasDTO.getMarkdowns().isEmpty()) {
            
            canvasMapper.insertMarkdowns(canvasDTO);
            
        }
    }


    @Override
    public CanvasVO getCanvas(int userId, int id) {
        CanvasVO canvasVO = new CanvasVO();
        canvasVO.setImages(canvasMapper.getImages(id));;
        canvasVO.setTexts(canvasMapper.getTexts(id));
        return canvasVO;
    }


    @Override
    public List<CanvasVO> loadCanvas() {
        List<CanvasDTO> canvasDTOs = canvasMapper.loadCanvas();
        List<CanvasVO> canvasVOs = new ArrayList<CanvasVO>();
        for (CanvasDTO canvasDTO : canvasDTOs) {
            CanvasVO canvasVO = new CanvasVO();
            canvasVO.setImages(canvasMapper.getImages(canvasDTO.getId()));
            canvasVO.setTexts(canvasMapper.getTexts(canvasDTO.getId()));
           
            List<Heritage> heritages = canvasMapper.getHeritages(canvasDTO.getId());
            // for(Heritage heritage:heritages){
            //     heritage.setItems(canvasMapper.getHeritageItems(heritage.getId()));
            // }
            List<MarkdownBox> markdowns = canvasMapper.getMarkdowns(canvasDTO.getId());
            canvasVO.setMarkdowns(markdowns);
            canvasVO.setHeritages(heritages);
            canvasVOs.add(canvasVO);
        }
        return canvasVOs;
    }
    
    @Override
    public List<HeritageItem> getNonePrivateHeritage(Long heritageId) {
        // 获取所有遗产项
        List<HeritageItem> allItems = canvasMapper.getAllHeritageItemsByHeritageId(heritageId);
        long userId = BaseContext.getCurrentId();
        // 返回所有非私密的遗产项，以及已经被当前用户获得的私密遗产项
        return allItems.stream()
                .filter(item -> !item.getIsPrivate() || 
                        (item.getIsPrivate() && item.getUserId() == userId))
                .collect(java.util.stream.Collectors.toList());
    }

    @Override
    public CompletableFuture<HeritageItem> getPrivateHeritageAsync(Long heritageId) {
        // 获取当前用户ID
        Long currentUserId = BaseContext.getCurrentId();
        
        // 创建CompletableFuture来异步处理结果
        CompletableFuture<HeritageItem> future = CompletableFuture.supplyAsync(() -> {
            // 获取指定heritageId下所有未被获得的私密遗产项
            List<HeritageItem> items = canvasMapper.getUnclaimedPrivateHeritageItems(heritageId);
            HeritageItem result = null;
            
            if (items != null && !items.isEmpty()) {
                // 随机选择一个遗产项
                int randomIndex = (int) (Math.random() * items.size());
                HeritageItem selectedItem = items.get(randomIndex);
                
                // 随机决定是否能获得遗产（模拟"有缘"）
                if (Math.random() < 0.5) { // 50%的概率获得遗产
                    // 设置用户ID
                    selectedItem.setUserId(currentUserId);
                    
                    // 使用乐观锁更新数据库
                    try {
                        boolean updated = canvasMapper.updateHeritageItemOwner(selectedItem);
                        if (updated) {
                            result = selectedItem;  // 更新成功，返回获得的遗产项
                        }
                    } catch (Exception e) {
                        // 处理并发更新异常
                        result = null;
                    }
                }
            }
            
            return result;
        });
        
        return future;
    }

    // @KafkaListener(topics = "${kafka.topics.heritage-requests}", groupId = "${spring.kafka.consumer.group-id}")
    // public void processHeritageRequest(@Header(KafkaHeaders.RECEIVED_KEY) String key, 
    //                                  @Payload HeritageRequest request) {
    //     // 处理请求
    //     HeritageItem result = null;
        
    //     // 获取指定heritageId下所有未被获得的私密遗产项
    //     List<HeritageItem> items = canvasMapper.getUnclaimedPrivateHeritageItems(request.getHeritageId());
    //     if (items != null && !items.isEmpty()) {
    //         // 随机选择一个遗产项
    //         int randomIndex = (int) (Math.random() * items.size());
    //         HeritageItem selectedItem = items.get(randomIndex);
            
    //         // 随机决定是否能获得遗产（模拟"有缘"）
    //         if (Math.random() < 0.5) { // 50%的概率获得遗产
    //             // 设置用户ID
    //             selectedItem.setUserId(request.getUserId());
                
    //             // 更新数据库
    //             try {
    //                 boolean updated = canvasMapper.updateHeritageItemOwner(selectedItem);
    //                 if (updated) {
    //                     result = selectedItem;  // 更新成功，返回获得的遗产项
    //                 }
    //             } catch (Exception e) {
    //                 // 处理并发更新异常
    //                 result = null;
    //             }
    //         }
    //     }
        
    //     // 完成对应的CompletableFuture
    //     CompletableFuture<HeritageItem> future = pendingRequests.remove(key);
    //     if (future != null) {
    //         future.complete(result);
    //     }
    // }

    @Override
    public List<CanvasVO> getCanvasList(Long userId) {
        List<CanvasVO> canvasVOs = canvasMapper.getCanvasList(userId);
        return canvasVOs;
    }

    @Override
    public void deleteCanvas(long canvasId,boolean justContent) {
        if(!justContent){
            canvasMapper.deleteCanvas(canvasId);
        }
        List<Heritage> heritages = canvasMapper.getHeritages(canvasId);
        for(Heritage heritage:heritages){
            canvasMapper.deleteHeritageItems(heritage.getId());
        }
        canvasMapper.deleteImages(canvasId);
        canvasMapper.deleteTexts(canvasId);
        canvasMapper.deleteMarkdowns(canvasId);
    }


    @Override
    public CanvasVO getCanvasById(long userId,long canvasId){
        CanvasVO canvasVO = null;
        if(userId != -1){
            canvasVO = canvasMapper.getCanvasBy2Id(userId,canvasId);
        }
        else{
            canvasVO = canvasMapper.getCanvasById(canvasId);
        }
        // System.out.println(canvasVO.getId());
        canvasVO.setImages(canvasMapper.getImages(canvasId));
        canvasVO.setTexts(canvasMapper.getTexts(canvasId));
       
        List<Heritage> heritages = canvasMapper.getHeritages(canvasId);
        for(Heritage heritage:heritages){
            heritage.setItems(canvasMapper.getHeritageItems(heritage.getId()));
        }
        canvasVO.setHeritages(heritages);
        canvasVO.setMarkdowns(canvasMapper.getMarkdowns(canvasId));
        return canvasVO;
    }

}
