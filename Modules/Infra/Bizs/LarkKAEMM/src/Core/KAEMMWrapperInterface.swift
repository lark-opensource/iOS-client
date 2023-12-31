//
//  KAEMMAssembly.swift
//  LarkKAEMM
//
//  Created by Crazy凡 on 2021/9/6.
//

import Foundation

/// VPN 登录配置
public enum VPNLoginConfig {

    /// account
    case account(String)

    /// password
    case password(String)
}

/// VPN 类 SDK 接入接口
public protocol KAVPNWrapperInterface {
    /// 登录结果回调： Swift.Result<String(Login info), Error>
    typealias CompletionHanlder = (Result<String, Error>) -> Void

    /// 登录 VPN SDK
    /// - Parameters:
    ///   - config: 登录的参数，使用枚举数组是为方便更新或者插入新的配置
    ///   - completion: 登录结果回调
    func login(with configs: [VPNLoginConfig], _ completion: CompletionHanlder?)

    /// 登出方法
    func logout()
}

extension KAVPNWrapperInterface {
    func login(with configs: [VPNLoginConfig], _ completion: CompletionHanlder?) {
        completion?(.success(""))
    }

    func logout() {}
}
