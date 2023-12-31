//
//  WPError.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/4/12.
//

import Foundation
import SwiftyJSON

final class WorkplaceError: Error {
    let httpCode: Int
    var serverCode: Int?
    let code: Int
    var errorMessage: String?

    init(code: Int, originError: NSError?) {
        self.code = code
        if let originError = originError {
            self.serverCode = originError.code
            self.errorMessage = originError.localizedDescription
            self.httpCode = originError.userInfo[WPNetworkConstants.httpCode] as? Int ?? 0
        } else {
            self.httpCode = 200
        }
    }

    init?(response: JSON) {
        let serverCode = response["code"].int
        guard serverCode != 0 else {
            return nil
        }
        self.httpCode = response[WPNetworkConstants.httpCode].int ?? 0
        self.code = WPTemplateErrorCode.server_error.rawValue
        self.serverCode = serverCode
        self.errorMessage = response["msg"].stringValue
    }
}

enum WPTemplateErrorCode: Int {
    // 1. 变量名尽量不带下划线，考虑优化
    // 2. 类型名首字母大写
    // swiftlint:disable identifier_name
    case server_error = 100
    enum GetTemplateList: Int {
        case json_decode_error = 101
    }
    enum DownloadTemplate: Int {
        case invalid_schema = 101
        case json_decode_error = 102
        case bad_template = 103
    }
    enum GetPlatformComponent: Int {
        case invalid_module_data = 101
        case update_module_data_fail = 102
        case empty_request = 103
        case json_decode_error = 104
    }
    enum GetExternalComponent: Int {
        case empty_request = 101
    }
    enum GetTemplateBlock: Int {
        /// iOS only: 101、102
        /// Android+iOS: 104、105
        case empty_entity_and_guide_info = 101
        case nil_self = 102
        case parse_entity_fail = 104
        case parse_guide_info_fail = 105
    }
    // swiftlint:disable identifier_name
}

struct WPLoadTemplateError: Error {
    enum WPLoadTemplateFailFrom: Int {
        case invalid_template = 1
        case download_template = 2
        case get_platform_component = 3
    }

    let error: WPTemplateError
    let failFrom: WPLoadTemplateFailFrom
}

enum WPLoadTemplateShowErrorViewFrom: Int {
    case load_portal = 1
    case load_template = 2
}
