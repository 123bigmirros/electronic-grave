package com.example.grave.controller.user;

import com.example.grave.common.result.Result;
import com.example.grave.pojo.entity.Path;
import com.example.grave.service.FileStorageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@CrossOrigin
@RequestMapping("/api/upload")
public class FileUploadController {

    @Autowired
    private FileStorageService fileStorageService;

    @PostMapping(value = "/image", produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseBody
    public Result<Path> uploadImage(@RequestParam("file") MultipartFile file) {
        try {
            String fileUrl = fileStorageService.storeFile(file);
            System.out.println("上传图片成功: " + fileUrl);
            Path path = new Path();
            path.setPath(fileUrl);
            return Result.success(path);
        } catch (Exception e) {
            e.printStackTrace();
            return Result.error("图片上传失败：" + e.getMessage());
        }
    }
} 