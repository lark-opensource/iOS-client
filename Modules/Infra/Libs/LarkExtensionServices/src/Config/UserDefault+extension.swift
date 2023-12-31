//
//  UserDefault+extension.swift
//  LarkExtensionServices
//
//  Created by 王元洵 on 2021/3/29.
//

import Foundation

/// 对UserDefaults的拓展，提供extension相关接口
public extension UserDefaults {
    /// extenison和主App共享的UserDefaults
    static var `extension`: UserDefaults? {
        #if DEBUG
        UserDefaults(suiteName: "group.com.bytedance.ee.lark.yzj")
        #else
        UserDefaults(suiteName: AppConfig.AppGroupName)
        #endif
    }
}
