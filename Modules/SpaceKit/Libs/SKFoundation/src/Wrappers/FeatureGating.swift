//
//  FeatureGating.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/12/27.
//

import Foundation

/// Lark 的 FG，暂时只能支持 Bool
@propertyWrapper
public final class FeatureGating<Value> {
    public let key: String
    let defaultValue: Value
    var isStatic: Bool = false // 当前用户获取FG，是否保持相同结果
    var needLog: Bool = true //同一个租户登录后，不重复打印FG

    /// 初始化 Lark FG
    /// - Parameters:
    ///   - wrappedValue: 拉取不到fg时的默认值
    ///   - key: Fg 的 key
    public init(wrappedValue: Value, key: String, isStatic: Bool = false) {
        defaultValue = wrappedValue
        self.key = key
        self.isStatic = isStatic
        self.addObserver()
    }

    public init(defaultValue: Value, key: String, isStatic: Bool = false) {
        self.defaultValue = defaultValue
        self.key = key
        self.isStatic = isStatic
        self.addObserver()
    }

    func addObserver() {
        let userDidLoginNotification = Notification.Name(rawValue: "docs.bytedance.notification.name.userDidLogin")
        NotificationCenter.default.addObserver(self, selector: #selector(userDidLogin), name: userDidLoginNotification, object: nil)
    }

    @objc
    func userDidLogin() {
        self.needLog = true
    }

    public var projectedValue: FeatureGating<Value> { self }

    public var wrappedValue: Value {
        defer { needLog = false }
        if let value = HostAppBridge.shared.call(GetLarkFeatureGatingService(key: key, isStatic: isStatic, defaultValue: defaultValue as? Bool ?? false)) as? Value {
            if needLog {
                DocsLogger.info("Get FeatureGate value success",
                                extraInfo: ["key": key, "value": value],
                                component: LogComponents.larkFeatureGate)
            }
            return value
        }
        if needLog {
            DocsLogger.error("Get FeatureGate value failed, fallback to defaultValue",
                             extraInfo: ["key": key, "defaultValue": defaultValue],
                             component: LogComponents.larkFeatureGate)
        }
        return defaultValue
    }
}
