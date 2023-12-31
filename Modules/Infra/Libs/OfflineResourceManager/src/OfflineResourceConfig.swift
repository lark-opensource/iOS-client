//
//  OfflineResourceConfig.swift
//  OfflineResourceManager
//
//  Created by Miaoqi Wang on 2020/9/3.
//

import Foundation

/// resource config
public struct OfflineResourceConfig {
    /// app id
    public let appId: String
    /// app version
    public let appVersion: String
    /// directory where caches store
    public let cacheRootDirectory: String?
    /// device id
    public internal(set) var deviceId: String
    /// domain to request remote data
    public internal(set) var domain: String
    /// is boe
    public let isBoe: Bool

    /// init config
    /// - Parameters:
    ///   - domain: network domain used to request remote resource
    ///   - cacheRootDirectory: set nil will use default path Library/Caches
    public init(appId: String,
                appVersion: String,
                deviceId: String,
                domain: String,
                cacheRootDirectory: String? = nil,
                isBoe: Bool = false) {
        self.appId = appId
        self.appVersion = appVersion
        self.deviceId = deviceId
        self.domain = domain
        self.cacheRootDirectory = cacheRootDirectory
        self.isBoe = isBoe
    }

    static func empty() -> OfflineResourceConfig {
        return OfflineResourceConfig(appId: "", appVersion: "", deviceId: "", domain: "")
    }
}
