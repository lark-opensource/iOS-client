//
//  ENV.swift
//  LarkSnCService
//
//  Created by Bytedance on 2022/8/25.
//

import Foundation

/// 环境参数
public protocol Environment {

    /// 是否是 Debug 模式
    var debug: Bool { get }

    /// 是否是 Inhouse 模式
    var inhouse: Bool { get }

    /// 是否是 BOE Env
    var boe: Bool { get }

    /// 是否是KA用户
    var isKA: Bool { get }

    /// 当前用户 ID
    var userId: String { get }

    /// 当前租户 ID
    var tenantId: String { get }

    /// 是否登录
    var isLogin: Bool { get }

    /// 用户账号品牌
    var userBrand: String { get }

    /// 安装包品牌
    var packageId: String { get }

    /// 可以通过该函数获取任意 key 对应的值
    /// 注册服务的业务方根据 SDK 要求注入特定 Key 值数据
    /// - Parameter key: Key 键
    /// - Returns: 对应的 Value 值
    func get<T>(key: String) -> T?
}
