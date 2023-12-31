//
//  AppGroup.swift
//  LarkExtensionServices
//
//  Created by Supeng on 2021/5/7.
//

import Foundation

/// App Group命名空间，存储了一些基本信息
public enum AppGroup {
    /// App Group的名字
    public static let name = Bundle.main.infoDictionary?["EXTENSION_GROUP"] as? String

    /// App ID
    public static let appID = Bundle.main.infoDictionary?["SSAppID"] as? String
}
