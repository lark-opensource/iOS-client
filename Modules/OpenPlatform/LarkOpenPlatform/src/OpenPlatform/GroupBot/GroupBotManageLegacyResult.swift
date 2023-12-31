//
//  GroupBotManageLegacyResult.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/29.
//

import Foundation

/// 机器人管理相关后端遗留响应结果数据
struct GroupBotManageLegacyResult: Codable {
    static let defaultErrorCode: Int = -1
    /// 错误提示
    let errorMessageToShow: String?
    /// 错误码
    let code: Int
    /// 是否成功
    var success: Bool {
        return (code == 0)
    }

    private enum CodingKeys: String, CodingKey {
        case errorMessageToShow = "msg"
        case code = "code"
    }
}
