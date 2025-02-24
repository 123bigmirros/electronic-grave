package com.example.grave.service;

import com.example.grave.pojo.dto.UserLoginDTO;
import com.example.grave.pojo.dto.UserRegisterDTO;
import com.example.grave.pojo.vo.UserVO;

public interface UserService {
    public UserVO login(UserLoginDTO userLoginDTO);
    public UserVO register(UserRegisterDTO userRegisterDTO);
    public UserVO getUserInfo(Long userId);
}
