//
//  AppConfig.swift
//  LarkExtensionServices
//
//  Created by 王元洵 on 2021/5/10.
//

import Foundation
import LarkStorageCore

/// AppConfig命名空间，存储了一些基本信息
public enum AppConfig {
    /// App Group的名字
    public static var AppGroupName: String? {
    #if DEBUG
    // debug 环境下使用该值，才能正常调试
    return "group.com.bytedance.ee.lark.yzj"
    #else
    return Bundle.main.infoDictionary?["EXTENSION_GROUP"] as? String
    #endif
    }

    /// App ID
    public static let appID: String? =  KVPublic.SharedAppConfig.appId.value()

    /// App Name
    public static let appName: String? = KVPublic.SharedAppConfig.appName.value()

    /// Env Type
    public static var envType: Int? {
        KVPublic.SharedAppConfig.envType.value()
    }

    /// Env Unit
    public static var unit: String? {
        KVPublic.SharedAppConfig.envUnit.value()
    }

    /// x-tt-env
    public static var xTTEnv: String? {
        KVPublic.SharedAppConfig.ttenv.value()
    }

    /// 是否是Lark
    public static var isLark: Bool? {
        KVPublic.SharedAppConfig.isLark.value()
    }

    public static let teaUploadDiffTimeInterval: Double = KVPublic.SharedAppConfig.teaUploadDiffTimeInterval.value() ?? 300_000
    public static let teaUploadDiffNumber: Int = KVPublic.SharedAppConfig.teaUploadDiffNumber.value() ?? 10
    public static let logEnable: Bool = KVPublic.SharedAppConfig.logEnable.value() ?? true
    public static let logBufferSize: Int = KVPublic.SharedAppConfig.logBufferSize.value() ?? 100

    /// 域名
    public static func getDomain(_ userId: String?) -> [String: [String]]? {
        guard let userId = userId else { return nil }
        let userDomainStorage = UserDomainStorage(userID: userId)
        return userDomainStorage.getUserDomain() ?? KVPublic.SharedAppConfig.domainMap.value()
    }

    public static func getGateway(_ userId: String?) -> String? {
        guard let userId = userId else { return nil }
        if let domainMap = Self.getDomain(userId),
           let apiDomain = domainMap["api"] {
            var gateWay = apiDomain.map { "https://" + $0 + "/im/gateway/" }
            return gateWay.first
        } else {
            /// 兜底，历史存储数据，无用户态
            let domainMap = KVPublic.SharedAppConfig.domainMap.value()
            return domainMap?["gateway"]?.first
        }
    }

    public static func getApplogURL(_ userId: String?) -> String? {
        guard let userId = userId else { return nil }
        if let domainMap = Self.getDomain(userId),
           let tea = domainMap["tt_tea"]?.first {
            var teaURL = tea
            if !teaURL.hasPrefix("http") {
                teaURL = "https://" + teaURL
            }
            if teaURL.hasSuffix("/") {
                teaURL += "service/2/app_log/"
            } else {
                teaURL += "/service/2/app_log/"
            }
            return teaURL
        }
        /// 兜底，历史存储数据，无用户态
        return KVPublic.SharedAppConfig.applogUrl.value()
    }
}
