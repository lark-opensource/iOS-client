//
//  RecoveryContext+RecoveryScene.swift
//  OPSDK
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
/// 错误恢复框架针对开放应用的一个便捷入口，开放应用的错误发生有多种场景，在userInfo中增加一个scene来标识各种不同的场景，在OPSDK层统一设置

/// recoveryScene数据在userInfo中的键
private let userInfoRecoverySceneKey = "scene"

public extension RecoveryContext {

    /// 设置或读取userInfo中的RecoveryScene
    var recoveryScene: RecoveryScene? {
        get {
            return valueFromUserInfo(for: userInfoRecoverySceneKey) as? RecoveryScene
        }
        set {
            setUserInfo(value: newValue, key: userInfoRecoverySceneKey, weakReference: false)
        }
    }
}

/// 开放应用层的错误发生场景
@objcMembers
public final class RecoveryScene: NSObject {
    public let value: String

    init(value: String) {
        self.value = value
    }
}


public extension RecoveryScene {

    /// 小程序页面Crash次数过多
    static let gadgetPageCrashOverload = RecoveryScene(value: "gadget_page_crash_overload")

    /// 小程序加载失败
    static let gadgetFailToLoad = RecoveryScene(value: "gadget_fail_to_load")

    /// 小程序运行时失败
    static let gadgetRuntimeFail = RecoveryScene(value: "gadget_runtime_fail")

    /// 手动刷新小程序
    static let gadgetReloadManually = RecoveryScene(value: "gadget_reload_manually")

}
