//
//  WPErrorPageInfoHelper.swift
//  LarkWorkplace
//
//  Created by doujian on 2022/7/19.
//

import LarkSetting
import SwiftyJSON
import LKCommonsLogging
import ECOProbeMeta

/// WPErrorPageInfoHelper 用于 error message 解析与构造
enum WPErrorPageInfoHelper {

    /// workplace_error_page_map 配置 model
    struct WPErrorPageInfoMap: Codable {

        struct Info: Codable {
            let message: String
            let code: String
        }

        static let settingKey: String = "workplace_error_page_map"
        let messageMapping: [String: [String: Info]]
    }

    static let logger = Logger.log(WPErrorPageInfoMap.self)

    private static var errorPageInfoMap: WPErrorPageInfoMap? = {
        @Setting(key: .make(userKeyLiteral: "workplace_error_page_map"))
        var config: WPErrorPageInfoMap?
        return config
    }()

    /// get error message with monitor code
    /// - Parameter monitorCode: monitorCode confirm to OPMonitorCodeProtocol
    /// - Returns: error message
    static func errorMessage(with monitorCode: OPMonitorCodeProtocol, isCodeChangeLine: Bool = false) -> String? {
        logger.info("WPErrorPageInfoHelper get errorMessage", additionalData: [
            "errorPageInfoMap is empty": "\(errorPageInfoMap == nil)",
            "MonitorDomain": monitorCode.domain,
            "monitorCode": "\(monitorCode.code)",
            "monitorMessage": monitorCode.message
        ])
        guard let map = errorPageInfoMap else {
            // 当配置为空是返回 nil
            return nil
        }
        if let info = map.messageMapping[monitorCode.domain]?[monitorCode.message] as? WPErrorPageInfoMap.Info {
            let changeLineStr: String = isCodeChangeLine ? "\n" : ""
            return info.message + changeLineStr + "(\(info.code))"
        }
        // 当没有找到对应的 message 时，返回默认 message【加载失败，点击刷新】
        return nil
    }
}
