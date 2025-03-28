package com.example.grave;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
@SpringBootApplication
@MapperScan("com.example.grave.mapper")
@ComponentScan(basePackages = "com.example.grave")

public class GraveApplication {

	public static void main(String[] args) {
		SpringApplication.run(GraveApplication.class, args);
	}

}
