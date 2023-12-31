//
//  OPEventContext.swift
//  EventBubble
//
//  Created by Nicholas Tau on 2020/12/5.
//

import Foundation
import ECOInfra

/// to store the context relationship when event handling
public final class OPEventContext: NSObject {
    
    /// 事件传递过程中可增删变化的上下文信（为了避免被随意篡改，只允许通过 setContextInfo 和 contextInfo 接口获得和设置）
    private var contextInfo: [AnyHashable: Any] = [:]
    private var userInfo: [AnyHashable: Any] = [:]
    
    public init(userInfo: [AnyHashable:Any]) {
        self.userInfo = userInfo
        super.init()
    }
}


/// 上下文信息的 Key
extension OPEventContext {
    
    public func setContextInfo(_ key: String, value: Any?, weak: Bool) {
        guard let value = value else {
            contextInfo[key] = nil
            return
        }
        if let object = value as? AnyObject, weak {
            contextInfo[key] = WeakReference(value: object)
        } else {
            contextInfo[key] = value
        }
    }
    
    public func contextInfo(_ key: String) -> Any? {
        guard let value = contextInfo[key] else {
            return nil
        }
        if let value = value as? WeakReference<AnyObject> {
            return value.value
        }
        return value
    }
    
    public func allContextInfo() -> [AnyHashable : Any] {
        return contextInfo
    }
}
