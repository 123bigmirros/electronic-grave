package com.example.grave;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("com.example.grave.mapper")
public class GraveApplication {

	public static void main(String[] args) {
		SpringApplication.run(GraveApplication.class, args);
	}

}
