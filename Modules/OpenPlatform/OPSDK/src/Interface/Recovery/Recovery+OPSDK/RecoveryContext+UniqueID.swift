//
//  RecoveryContext+UniqueID.swift
//  OPSDK
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPFoundation
/// 错误恢复框架针对开放应用的一个便捷入口，开放应用必须拥有uniqueID，所以在OPSDK层进行统一设置

/// uniqueID数据在userInfo中的键
private let userInfoUniqueIDKey = "uniqueID"

public extension RecoveryContext {
    /// 设置或者读取context中的uniqueID
    var uniqueID: OPAppUniqueID? {
        get {
            return valueFromUserInfo(for: userInfoUniqueIDKey) as? OPAppUniqueID
        }
        set {
            setUserInfo(value: newValue, key: userInfoUniqueIDKey, weakReference: false)
        }
    }

    /// 根据context中携带的uniqueID信息，尝试获取对应的Container容器
    var container: OPContainerProtocol? {
        return OPApplicationService.current.getContainer(uniuqeID: uniqueID)
    }
}
