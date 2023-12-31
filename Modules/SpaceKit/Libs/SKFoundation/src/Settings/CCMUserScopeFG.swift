//
//  CCMUserScopeFG.swift
//  SKFoundation
//
//  Created by ByteDance on 2023/11/7.
//

import Foundation
import LarkContainer
import LarkSetting

@propertyWrapper
public final class CCMUserScopeFG {
    
    private enum Value {
        case `static`(Bool)
        case `dynamic`(closure: () -> Bool)
    }
    
    private let key: String
    
    private let isStatic: Bool
    
    private var value: Value?
    
    private var printLog = true // 每个FG只打印一次
    
    /// 初始化方法
    /// - Parameters:
    ///   - key: 键名
    ///   - isStatic: 是否静态值，静态值租户生命周期内不变，动态值每次实时读取settings
    ///   - userResolver: 用户态UserResolver
    public init(key: String,
                isStatic: Bool = true,
                userResolver: UserResolver = Container.shared.getCurrentUserResolver(compatibleMode: true)) {
        
        self.key = key
        self.isStatic = isStatic
        self.updateValue(userResolver: userResolver)
        
        let notification = Notification.Name(rawValue: "docs.bytedance.notification.name.userDidLogin")
        NotificationCenter.default.addObserver(self, selector: #selector(userDidLogin), name: notification, object: nil)
    }
    
    public var wrappedValue: Bool {
        let result: Bool
        switch self.value {
        case .static(let bool):
            result = bool
        case .dynamic(let closure):
            result = closure()
        case .none:
            result = false
        }
        print(key: key, value: result)
        return result
    }
    
    private func print(key: String, value: Bool) {
        if printLog {
            DocsLogger.info("Get FeatureGate value success",
                            extraInfo: ["key": key, "value": value],
                            component: LogComponents.larkFeatureGate)
        }
        printLog = false
    }
    
    @objc private func userDidLogin(_ noti: NSNotification) {
        printLog = true
        do {
            let userID = noti.userInfo?["userID"] as? String
            let ur = try Container.shared.getUserResolver(userID: userID)
            updateValue(userResolver: ur)
        } catch {
            DocsLogger.info("getUserResolver error:\(error)", component: LogComponents.larkFeatureGate)
        }
    }
    
    private func updateValue(userResolver: UserResolver) {
        let theKey = FeatureGatingManager.Key(stringLiteral: key)
        let fgService = userResolver.fg
        if isStatic {
            self.value = .static(fgService.staticFeatureGatingValue(with: theKey))
        } else {
            self.value = .dynamic(closure: { fgService.dynamicFeatureGatingValue(with: theKey) })
        }
    }
}
