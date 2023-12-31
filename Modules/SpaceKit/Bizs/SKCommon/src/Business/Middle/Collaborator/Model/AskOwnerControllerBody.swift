//
//  AskOwnerControllerBody.swift
//  SKCommon
//
//  Created by guoqp on 2021/11/8.
//

import Foundation
import EENavigator
import LarkUIKit
import SKUIKit

public struct AskOwnerControllerBody {
//    public static let pattern = "//client/docs/ask_owner"

    public var collaboratorID: String = ""
    public var ownerName: String?
    public var ownerID: String?
    public var needPopover: Bool = false
    public var docsType: Int = 0
    public var objToken: String = ""
    public var imageKey: String = ""
    public var title: String = ""
    public var isExternal: Bool = false
    public var isCrossTenanet: Bool = false
    public var roleType: Int = 0
    public var detail: String = ""

    public init(queryDict: [String: String], fromVc: UIViewController) {
        self.needPopover = Display.pad &&
            fromVc.view.window?.lkTraitCollection.horizontalSizeClass == .regular
        if let docToken = queryDict["docToken"] {
            self.objToken = docToken
        }
        if let invitedId = queryDict["invitedId"] {
            self.collaboratorID = invitedId
        }
        if let ownerName = queryDict["ownerName"] {
            self.ownerName = ownerName
        }
        if let ownerId = queryDict["ownerId"] {
            self.ownerID = ownerId
        }
        if let docsType = queryDict["docType"], let value = Int(docsType) {
            self.docsType = value
        }
        if let imageKey = queryDict["invitedAvatarKey"] {
            self.imageKey = imageKey
        }
        if let title = queryDict["invitedName"] {
            self.title = title
        }
        if let isExternal = queryDict["isCrossTenant"], let value = Bool(isExternal) {
            self.isExternal = value
        }
        if let isCrossTenanet = queryDict["isCrossTenant"], let value = Bool(isCrossTenanet) {
            self.isExternal = value
        }
        if let roleType = queryDict["invitedType"], let value = Int(roleType) {
            self.roleType = value
        }
    }
}

public struct EmbedDocAuthControllerBody: CodablePlainBody {
    public static let pattern = "//client/docs/embed"
    public var chatID: String = ""
    public var ownerName: String?
    public var ownerID: String?
    public var needPopover: Bool = false
    public var docsType: Int = 0
    public var objToken: String = ""
    public var chatAvatar: String = ""
    public var chatName: String = ""
    public var isExternal: Bool = false
    public var isCrossTenanet: Bool = false
    /// 聊天类型: 0 单聊  2 群聊
    public var chatType: Int = 0
    public var detail: String = ""
    public var taskId: String = ""

    public init(queryDict: [String: String], fromVc: UIViewController) {
        self.needPopover = Display.pad &&
            fromVc.view.window?.lkTraitCollection.horizontalSizeClass == .regular
        if let taskId = queryDict["taskId"] {
            self.taskId = taskId
        }
        if let docToken = queryDict["token"] {
            self.objToken = docToken
        }
        if let invitedId = queryDict["chatId"] {
            self.chatID = invitedId
        }
        if let ownerName = queryDict["ownerName"] {
            self.ownerName = ownerName
        }
        if let ownerId = queryDict["ownerId"] {
            self.ownerID = ownerId
        }
        if let docsType = queryDict["type"], let value = Int(docsType) {
            self.docsType = value
        }
        if let imageKey = queryDict["chatAvatar"] {
            self.chatAvatar = imageKey
        }
        if let title = queryDict["chatName"] {
            self.chatName = title
        }
        if let isExternal = queryDict["isCrossTenant"], let value = Bool(isExternal) {
            self.isExternal = value
        }
        if let isCrossTenanet = queryDict["isCrossTenant"], let value = Bool(isCrossTenanet) {
            self.isCrossTenanet = value
        }
        if let roleType = queryDict["chatType"], let value = Int(roleType) {
            self.chatType = value
        }
        if let detail = queryDict["chatDesc"] {
            //群描述
            self.detail = detail
        }
    }
}
