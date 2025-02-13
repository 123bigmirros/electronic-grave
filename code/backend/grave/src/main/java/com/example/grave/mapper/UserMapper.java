package com.example.grave.mapper;

import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Select;

import com.example.grave.pojo.dto.UserRegisterDTO;
import com.example.grave.pojo.entity.User;
import com.example.grave.pojo.vo.UserVO;

public interface UserMapper {
    @Insert("INSERT INTO user (username, password) VALUES (#{username}, #{password})")
    public UserVO register(UserRegisterDTO userRegisterDTO);

    @Select("SELECT * FROM user WHERE username = #{username}")
    public UserVO getUserByUsername(String username);
}
