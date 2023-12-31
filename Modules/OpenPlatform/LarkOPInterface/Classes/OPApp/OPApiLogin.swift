//
//  OPApiLogin.swift
//  LarkOPInterface
//
//  Created by laisanpin on 2021/9/1.
//  这个文件是提供主端调用小程序登录接口;
//  该方案是临时的,后续会有新方案进行替换;

import Foundation

public protocol OPApiLogin {
    /// 小程序登录接口
    /// - Parameters:
    ///   - appId: 小程序ID
    ///   - completion: 回调(非主线程); error为NSError; code为临时凭证码
    func gadgetLogin(_ appId: String, _ completion: @escaping(_ result: Result<String, Error>) -> Void);

    /// 添加小程序引擎ready通知
    func onGadgetEngineReady(_ callback: @escaping(_ isReady: Bool) -> Void)
    
    /// 移除小程序引擎ready通知
    func offGadgetEngineReady()
}
