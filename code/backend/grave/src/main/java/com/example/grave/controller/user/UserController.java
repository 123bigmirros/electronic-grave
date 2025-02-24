package com.example.grave.controller.user;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.grave.common.context.BaseContext;
import com.example.grave.common.result.Result;
import com.example.grave.pojo.dto.UserLoginDTO;
import com.example.grave.pojo.dto.UserRegisterDTO;
import com.example.grave.pojo.vo.UserVO;
import com.example.grave.service.UserService;

@RestController
@RequestMapping("/user/info")
@CrossOrigin(origins = "http://localhost:8080")
public class UserController {
    @Autowired
    private UserService userService;
    //login
    @PostMapping("/login")
    public Result<UserVO> login(@RequestBody UserLoginDTO userLoginDTO){
        UserVO userLoginVO = userService.login(userLoginDTO);
        // System.out.println(userLoginVO.getId());
        return Result.success(userLoginVO);
    }
    

    //register
    @PostMapping("/register")
    public Result<UserVO> register(@RequestBody UserRegisterDTO userRegisterDTO){
        UserVO userVO = userService.register(userRegisterDTO);
        return Result.success(userVO);
    }

    @PostMapping("/get")
    public Result<UserVO> getUserInfo(){
        System.out.println("getUserInfo");
        Long userId = BaseContext.getCurrentId();
        if(userId == -1){
            return Result.error("用户未登录");
        }
        UserVO userVO = userService.getUserInfo(userId);
        return Result.success(userVO);
    }
}
