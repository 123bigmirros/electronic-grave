package com.example.grave.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.lang.NonNull;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.io.File;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${file.upload-dir:uploads}")
    private String uploadDir;

    @Override
    public void addResourceHandlers(@NonNull ResourceHandlerRegistry registry) {
        // 转换为绝对路径
        Path uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
        String resourceLocation = "file:" + uploadPath.toString() + File.separator;
        
        System.out.println("【关键】静态资源目录配置: /uploads/** -> " + resourceLocation);
        
        // 添加两种映射方式增加兼容性
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(resourceLocation);
        
        // 如果前端被打包到static目录，确保它能被正确访问
        registry.addResourceHandler("/**")
                .addResourceLocations("classpath:/static/");
    }
} 