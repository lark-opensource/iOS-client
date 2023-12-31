//
//  Notification+Infra.swift
//  SKInfra
//
//  Created by ByteDance on 2023/4/13.
//

import Foundation

public extension Notification.Name {
    /// FG请求成之后的通知
    static let minaConfigFinishRequest = Notification.Name(rawValue: "docs.bytedance.notification.name.minaConfigFinishRequest")
    
    // MARK: - FE FullPackage ready
    static let feFullPackageHasReady = Notification.Name(rawValue: "docs.bytedance.notification.name.feFullPackageHasReady")
}
