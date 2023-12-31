//
//  OPBlockSDK.swift
//  OPBlock
//
//  Created by 王飞 on 2021/8/11.
//
import LKCommonsLogging

/// SDK 相关配置信息
public struct OPBlockSDK {
    /// Blockit 版本号
    public static let runtimeSDKVersion = "1.52.0"
    static let logger = Logger.log(OPBlockSDK.self, category: "OPBlockSDK")

    /// 比较 meta 期望版本和当前 sdk 的版本
    /// - Parameter version: meta 中的版本
    /// - Returns: 如果当前 sdk 版本小于期望版本，则是 false
    public static func isLegalVersion(_ version: String?) -> Bool {
        guard let v = version else {
            return true
        }
        return runtimeSDKVersion.compare(v, options: .numeric) != .orderedAscending
    }
}

