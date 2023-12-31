//
//  PermissionSSCUpgradeService.swift
//  SKCommon
//
//  Created by X-MAN on 2023/3/27.
//

import Foundation

extension Notification.Name {
    public static let SSCUpgradeNotification = Notification.Name("SSCUpgradeNotification")
}

public final class PermissionSSCUpgradeService: BaseJSService, JSServiceHandler {
        
    public var handleServices: [DocsJSService] {
        return [.sscUpgradeNotify]
    }
    
    public func handle(params: [String : Any], serviceName: String) {
        NotificationCenter.default.post(name: .SSCUpgradeNotification, object: nil, userInfo: params)
    }
}
