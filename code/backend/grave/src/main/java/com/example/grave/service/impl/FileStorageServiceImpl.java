package com.example.grave.service.impl;

import com.example.grave.service.FileStorageService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@Service
public class FileStorageServiceImpl implements FileStorageService {

    private final Path fileStorageLocation;

    public FileStorageServiceImpl(@Value("${file.upload-dir:./uploads}") String uploadDir) {
        // 使用相对于项目的路径
        this.fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        
        try {
            // 确保目录存在，如果不存在则创建
            Files.createDirectories(this.fileStorageLocation);
            System.out.println("文件上传目录: " + this.fileStorageLocation);
        } catch (Exception ex) {
            throw new RuntimeException("无法创建文件上传目录", ex);
        }
    }

    @Override
    public String storeFile(MultipartFile file) {
        // 检查文件类型
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new RuntimeException("只能上传图片文件");
        }
        
        // 规范化文件名
        String originalFileName = StringUtils.cleanPath(
            file.getOriginalFilename() != null ? file.getOriginalFilename() : "image.jpg"
        );
        String fileExtension = "";
        
        if (originalFileName.contains(".")) {
            fileExtension = originalFileName.substring(originalFileName.lastIndexOf("."));
        }
        
        // 生成唯一文件名
        String fileName = UUID.randomUUID().toString() + fileExtension;

        try {
            // 检查文件名是否包含非法字符
            if (fileName.contains("..")) {
                throw new RuntimeException("文件名包含非法路径序列 " + fileName);
            }

            // 保存文件到目标位置
            Path targetLocation = this.fileStorageLocation.resolve(fileName);
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);
            
            System.out.println("文件已保存到: " + targetLocation);

            // 返回相对路径，让前端直接使用
            return "/uploads/" + fileName;
        } catch (IOException ex) {
            throw new RuntimeException("文件存储失败: " + ex.getMessage(), ex);
        }
    }
} 