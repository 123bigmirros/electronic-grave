package com.example.grave.service.impl;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
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

@Service
public class CanvasServiceImp implements CanvasService {
    @Autowired
    private CanvasMapper canvasMapper;

    
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
        
        // 返回所有非私密的遗产项，以及已经被当前用户获得的私密遗产项
        return allItems.stream()
                .filter(item -> !item.getIsPrivate() || 
                        (item.getIsPrivate() && item.getUserId() != 0))
                .collect(java.util.stream.Collectors.toList());
    }

    @Override
    public synchronized HeritageItem getPrivateHeritage(Long heritageId) {
        // 1. 获取指定heritageId下所有未被获得的私密遗产项
        List<HeritageItem> items = canvasMapper.getUnclaimedPrivateHeritageItems(heritageId);
        if (items == null || items.isEmpty()) {
            return null;
        }

        // 2. 随机选择一个遗产项
        int randomIndex = (int) (Math.random() * items.size());
        HeritageItem selectedItem = items.get(randomIndex);

        // 3. 随机决定是否能获得遗产（模拟"有缘"）
        if (Math.random() < 0.5) { // 50%的概率获得遗产
            // 4. 设置用户ID（这里暂时使用固定值1，实际应该从session获取）
            Long currentUserId = BaseContext.getCurrentId(); // TODO: 从session获取当前用户ID
            selectedItem.setUserId(currentUserId);

            // 5. 更新数据库
            try {
                boolean updated = canvasMapper.updateHeritageItemOwner(selectedItem);
                if (updated) {
                    return selectedItem;  // 更新成功，返回获得的遗产项
                }
            } catch (Exception e) {
                // 处理并发更新异常
                return null;
            }
        }

        return null;  // 未抽中或更新失败
    }


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
        CanvasVO canvasVO = canvasMapper.getCanvasBy2Id(userId,canvasId);
        // System.out.println("canvasVO:"+canvasVO);
        if (canvasVO == null) {
            return null;
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
