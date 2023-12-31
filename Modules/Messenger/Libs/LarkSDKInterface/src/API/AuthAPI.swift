//
//  AuthAPI.swift
//  Lark
//
//  Created by linlin on 2017/10/26.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel
import RustPB

public typealias SessionIdentifier = String

public protocol AuthAPI {

    /// 当前有效设备
    var validSessions: Observable<[RustPB.Basic_V1_Device]> { get }

    /// 是否通知
    var isNotify: Bool { get set }

    /// 通知状态变化信号
    var isNotifyObservable: Observable<Bool> { get }

    /// 登出客户端
    func logout() -> Observable<Void>

    /// 获取当前在线的终端用户
    ///
    /// - Returns: 激活状态的Session信息列表
    func fetchValidSessions() -> Observable<[RustPB.Basic_V1_Device]>

    /// 强制Session失效
    ///
    /// - Parameter
    ///  - identifier: 强制失效的Session Identifier
    ///
    /// - Return:
    func forceSessionInvalid(identifier: SessionIdentifier) -> Observable<Bool>

    /// 更新设备信息
    ///
    /// - Parameter
    ///  - Device Infomation
    ///
    /// - Return: 更新结果
    func updateDeviceInfo(deviceInfo: RustPB.Basic_V1_Device) -> Observable<Void>

    /// 设置请求后缀 用于在staging不同的环境调试
    ///
    /// - Parameter string: 前缀
    /// - Returns:
    func setReqIdSuffix(_ suffix: String) -> Observable<Void>

    /// 更新有效设备（eg. from push）
    /// - Parameter sessions: 在线设备
    func updateValidSessions(with sessions: [RustPB.Basic_V1_Device])
}
