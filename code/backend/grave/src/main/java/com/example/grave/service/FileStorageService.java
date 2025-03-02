package com.example.grave.service;

import org.springframework.web.multipart.MultipartFile;

public interface FileStorageService {
    /**
     * 存储上传的文件并返回访问URL
     * @param file 上传的文件
     * @return 文件访问URL
     */
    String storeFile(MultipartFile file);
} 