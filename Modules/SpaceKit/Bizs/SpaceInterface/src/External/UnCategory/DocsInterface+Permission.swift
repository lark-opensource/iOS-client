//
//  DocsInterface+Permission.swift
//  SpaceInterface
//
//  Created by peilongfei on 2023/5/8.
//  

import EENavigator

public struct AdjustSettingsBody: PlainBody {
    public static let pattern = "//client/docs/permission/secret/setting"

    /// base64加密，可能是wiki链接，用于打开文档
    public let docURL: String
    /// 文档token，不会是wiki token
    public let objToken: String
    /// 文档类型
    public let objType: Int
    /// 会话ID - 单聊，就是对方的用户ID - 群聊，就是群ID
    public let chatID: String
    /// 0 单聊, 2 群聊
    public let chatType: Int
    /// 会话对方的租户ID - 单聊，就是对方的用户所在的租户ID - 群聊，就是群归宿的租户ID
    public let targetTenantID: String
    /// 文档卡片ID，用于更新卡片信息
    public let docCardID: String

    public init(parameters: [String:String]) {
        docURL = parameters["docURL"] ?? ""
        objToken = parameters["objToken"] ?? ""
        objType = Int(parameters["objType"] ?? "0") ?? 0
        chatID = parameters["chatID"] ?? ""
        chatType = Int(parameters["chatType"] ?? "0") ?? 0
        targetTenantID = parameters["targetTenantID"] ?? ""
        docCardID = parameters["docCardID"] ?? ""
    }
}
