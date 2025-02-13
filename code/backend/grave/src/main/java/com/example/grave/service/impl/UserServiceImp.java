package com.example.grave.service.impl;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.example.grave.mapper.UserMapper;
import com.example.grave.pojo.dto.UserLoginDTO;
import com.example.grave.pojo.dto.UserRegisterDTO;
import com.example.grave.pojo.vo.UserVO;
import com.example.grave.service.UserService;

@Service
public class UserServiceImp implements UserService {

    @Autowired
    private UserMapper userMapper;
    @Override
    public UserVO login(UserLoginDTO userLoginDTO) {
        // TODO Auto-generated method stub
        //
        UserVO uservo = userMapper.getUserByUsername(userLoginDTO.getUsername());
        if(uservo == null||(!uservo.getPassword().equals(userLoginDTO.getPassword()))){
            UserVO userVO = new UserVO();
            userVO.setId(-1L);
            return userVO;
        }
        UserVO userLoginVO = new UserVO();
        userLoginVO.setUsername(uservo.getUsername());
        userLoginVO.setId(uservo.getId());
        return userLoginVO;
    }

    @Override
    public UserVO register(UserRegisterDTO userRegisterDTO) {
        UserVO uservo = userMapper.getUserByUsername(userRegisterDTO.getUsername());
        if(uservo != null){
            UserVO userVO = new UserVO();
            userVO.setId(-1L);
            return userVO;
        }
        UserVO userVO = userMapper.register(userRegisterDTO);
        return userVO;
    }
    
}
