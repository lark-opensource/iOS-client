//
//  guideTip.swift
//  LarkAppStateSDK
//
//  Created by  bytedance on 2020/9/25.
//

import Foundation

/// 不可用引导弹窗模型
struct GuideTipModel {
    let appID: String
    let appName: String
    let title: String
    let msg: String
    let buttons: [GuideTipButton]
}

/// 弹窗按钮模型
struct GuideTipButton {
    let content: String
    let schema: String
    let extras: [String: Any]
}

/// 引导按钮的Schema解析
class TipSchema {
    /// schema解析生成的URL
    var url: URL
    /// schema类型
    var schemaType: TipSchemaType
    /// 安装url参数的key
    static let urlKey = "url"
    /// 管理员id参数的key
    static let adminIdKey = "userId"

    init (schema: URL) {
        url = schema
        if let type = TipSchemaType(rawValue: url.path) {
            schemaType = type
        } else {
            AppStateSDK.logger.error("guide tip's schema is unkonwn")
            schemaType = .unKonwn
        }
    }

    /// 获取安装url
    func getInstallUrl() -> String? {
        guard schemaType == .install, let installUrl = url.queryParameters[TipSchema.urlKey] else {
            AppStateSDK.logger.error("guide tip's schema isn't install, get install url failed")
            return nil
        }
        return installUrl
    }

    /// 获取管理员
    func getAdminId() -> String? {
        guard schemaType == .contactAdmin, let adminUserId = url.queryParameters[TipSchema.adminIdKey] else {
            AppStateSDK.logger.error("guide tip's schema isn't contactAdmin, get install url failed")
            return nil
        }
        return adminUserId
    }

}

/// schema类型
enum TipSchemaType: String {
    /// 未知异常
    case unKonwn
    /// 确认
    case confirm = "/confirm"
    /// 取消
    case cancel = "/cancel"
    /// 申请可用性
    case applyAccess = "/apply/access"
    /// 安装应用
    case install = "/install"
    /// 联系管理员
    case contactAdmin = "/contact/admin"

}
