package com.example.grave.config;

import java.util.HashMap;
import java.util.Map;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.*;
import org.springframework.kafka.support.serializer.JsonDeserializer;
import org.springframework.kafka.support.serializer.ErrorHandlingDeserializer;

import com.example.grave.pojo.entity.HeritageRequest;

@Configuration
@EnableKafka
public class KafkaConfig {

    @Value("${kafka.topics.heritage-requests}")
    private String heritageRequestsTopic;
    
    @Value("${spring.kafka.bootstrap-servers}")
    private String bootstrapServers;
    
    @Value("${spring.kafka.consumer.group-id}")
    private String groupId;
    
    // 自定义主题配置
    @Bean
    public String heritageRequestsTopicName() {
        return heritageRequestsTopic;
    }
    
    // 创建消费者工厂
    @Bean
    public ConsumerFactory<String, HeritageRequest> consumerFactory() {
        Map<String, Object> props = new HashMap<>();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers);
        props.put(ConsumerConfig.GROUP_ID_CONFIG, groupId);
        
        // 配置JsonDeserializer信任所有包
        JsonDeserializer<HeritageRequest> jsonDeserializer = new JsonDeserializer<>(HeritageRequest.class);
        jsonDeserializer.addTrustedPackages("*");
        jsonDeserializer.setUseTypeMapperForKey(true);
        
        // 使用ErrorHandlingDeserializer包装JsonDeserializer，提供更好的错误处理
        ErrorHandlingDeserializer<HeritageRequest> errorHandlingDeserializer = 
                new ErrorHandlingDeserializer<>(jsonDeserializer);
        
        return new DefaultKafkaConsumerFactory<>(
                props, 
                new StringDeserializer(), 
                errorHandlingDeserializer
        );
    }
    
    // 配置监听器工厂
    @Bean
    public ConcurrentKafkaListenerContainerFactory<String, HeritageRequest> kafkaListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<String, HeritageRequest> factory = 
                new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());
        return factory;
    }
} 