//
//  OpenNavigationProtocol.swift
//  LarkQuickLaunchInterface
//
//  Created by phoenix on 2023/10/11.
//

import Foundation
import LarkTab

public struct OpenNavigationAppInfo {
    public let appType: AppType                 // 应用类型
    public var uniqueId: String                 // 唯一标识
    public var key: String                      // 用于跳转native app对应tab的key
    public var i18nName: [String: String]       // 多语言文案
    

    public init(uniqueId: String, key: String, appType: AppType, i18nName: [String: String]) {
        self.uniqueId = uniqueId
        self.key = key
        self.appType = appType
        self.i18nName = i18nName
    }
}

// 导航对外开放能力
public protocol OpenNavigationProtocol {
    // 导航数据变化通知
    func notifyNavigationAppInfos(appInfos: [OpenNavigationAppInfo])
}
