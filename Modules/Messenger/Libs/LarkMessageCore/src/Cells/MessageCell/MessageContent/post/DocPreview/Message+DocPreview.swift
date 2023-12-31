//
//  Message+DocPreview.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2020/5/27.
//

import UIKit
import Foundation
import LarkModel
import LarkAccountInterface
import LarkCore
import LarkFeatureGating
import LKCommonsLogging
import SwiftyJSON
import RustPB

/*
 chat等
 |---------------------------------------------------|
 |                                                   |
 |      docAbstract+thumbnailDetail+docType          |
 |                                                   |
 |---------------------------------------------------|
 |permissionDesc/shareStatusText       permissionText|（自己发的消息才显示，和自己的聊天隐藏）
 |---------------------------------------------------|
 |固定icon+shareText                                  |（别人发的消息才显示，和自己的聊天隐藏）
 |---------------------------------------------------|
 */
/*
 pin列表/un-pin弹窗
 |-------------------------------｜
 |docIcon/customIconKey  docTitle|（un-pin弹窗不会判断customIconKey）
 |                       docOwner|
 |-------------------------------|
*/

let docPreviewLogger = Logger.log(Message.self, category: "Module.IM.DocPreview")
/// 展示DocPreview需要的方法
extension Message {
    /// 当前要预览的Doc对应的权限信息
    var docPermission: RustPB.Basic_V1_DocPermission? {
        return self.docPermissions?[self.docKey]
    }

    /// 当前要预览的Doc
    var doc: RustPB.Basic_V1_Doc? {
        return self.docs?[self.docKey]
    }

    /// Doc类型
    var docType: RustPB.Basic_V1_Doc.TypeEnum {
        return self.doc?.type ?? .unknown
    }

    /// Doc预览图地址
    var docAbstract: String? {
        return self.doc?.abstract
    }

    /// 下载Doc预览图需要传的参数
    var thumbnailDetail: String {
        return self.url2Permissions?[self.docsUrl ?? ""]?.thumbnailDetail ?? ""
    }

    /// 自己发的消息时：单聊：对方人名，群聊：固定文案'赋予本会话成员权限'
    func permissionDesc(chat: Chat) -> String {
        switch chat.type {
        case .group, .topicGroup:
            return BundleI18n.LarkMessageCore.Lark_Docs_DocsActionsheetTip
        case .p2P:
            return chat.displayName
        @unknown default:
            return BundleI18n.LarkMessageCore.Lark_Docs_DocsActionsheetTip
        }
    }
    ///单页面、非单页面描述
    func singlePageDesc() -> String {
        switch singlePageState {
        case .normal:
            return ""
        case .container:
            return BundleI18n.LarkMessageCore.Lark_Chat_CardPart3CurrentSubPage
        case .singlePage:
            return BundleI18n.LarkMessageCore.Lark_Chat_CardPart3CurrentPage
        }
    }

    /// 自己发的消息时：分享状态
    var shareStatus: Int64 {
        return self.docPermission?.shareStatus ?? 0
    }

    var ownerIsInGroup: Bool {
        guard let permission = self.docPermission else {
            return false
        }
        let extraJSON = JSON(parseJSON: permission.extra)
        //判断owner是不是在群里，owner不在的群不允许ask owner
        let ownerIsInGroup = extraJSON["owner_in_group"].boolValue
        return ownerIsInGroup
    }

    var singlePageState: SinglePageState {
        guard let permission = self.docPermission else {
            return .normal
        }
        let extraJSON = JSON(parseJSON: permission.extra)
        docPreviewLogger.info("single_page_state:\(extraJSON["single_page_state"])")
        return SinglePageState(rawValue: extraJSON["single_page_state"].intValue) ?? .normal
    }

    ///判断会话类型是否是群
    func chatIsGroup(chat: Chat) -> Bool {
        var isGroup = false
        switch chat.type {
        case .group, .topicGroup:
            isGroup = true
        case .p2P:
            isGroup = false
        @unknown default:
            isGroup = false
        }
        return isGroup
    }

    ///自己发的消息
    func getShareStatusText(chat: Chat, name: String?) -> String {
        let isGroup = chatIsGroup(chat: chat)
        //自己无共享权限
        var text = shareStatusText
        if self.shareStatus == 6 || self.shareStatus == 7 {
            //接收方无权限，显示Ask Owner文案
            if self.docPermission?.receiverPerm == 0 && (!isGroup || ownerIsInGroup) {
                if isGroup {
                    //接收方为群显示部分群成员无权限
                    return BundleI18n.LarkMessageCore.Lark_Docs_ChatDocAskOwnerText + BundleI18n.LarkMessageCore.Lark_Docs_ChatDocAskOwnerButton
                } else {
                    //接收方为用户显示对方无权限
                    return BundleI18n.LarkMessageCore.Lark_Docs_AskOwerP2PText +
                        BundleI18n.LarkMessageCore.Lark_Docs_ChatDocAskOwnerButton
                }
            }
            //接收方有阅读权限
            if ((self.docPermission?.receiverPerm ?? 0) & 1) > 0 {
                //xxx可阅读 或 本会话成员可阅读
                text = BundleI18n.LarkMessageCore.Lark_Docs_ChatDocPermissionRead
            }
            //接收方有编辑权限
            if ((self.docPermission?.receiverPerm ?? 0) & 4) > 0 {
                //xxx可编辑 或 本会话成员可编辑
                text = BundleI18n.LarkMessageCore.Lark_Docs_ChatDocPermissionEdit
            }

            //接收方有权限
            if self.docPermission?.receiverPerm ?? 0 > 0 {
                if isGroup {
                    return BundleI18n.LarkMessageCore.Lark_Docs_ChatDocPermSetText(text)
                }
                return (name ?? "") + text
            }
        }
        guard let permission = self.docPermission else {
            return text
        }
        let extraJSON = JSON(parseJSON: permission.extra)
        // 是否是首次分享授权
        let sendCardAuthPerm = extraJSON["send_card_auth_perm"].boolValue
        // 发送者和文档owner是否不同租户
        let senderIsExternal = permission.senderIsExternal
        let isCrossTenant = chat.isCrossTenant
        // 外部文档发到内部
        if senderIsExternal && !isCrossTenant && sendCardAuthPerm {
            if isGroup {
                text = BundleI18n.LarkMessageCore.Lark_Permission_ExternalOwnerShareTips + BundleI18n.LarkMessageCore.Lark_Permission_CancelGrantButton
            } else {
                text = BundleI18n.LarkMessageCore.Lark_Permission_ExternalPersonTips + BundleI18n.LarkMessageCore.Lark_Permission_CancelGrantButton
            }
        } else if !senderIsExternal && isCrossTenant && sendCardAuthPerm {
            // 内部文档发到外部
            if isGroup {
                text = BundleI18n.LarkMessageCore.Lark_Permission_ChatExternalDesc + BundleI18n.LarkMessageCore.Lark_Permission_CancelGrantButton
            } else {
                text = BundleI18n.LarkMessageCore.Lark_Permission_ExternalPersonTips + BundleI18n.LarkMessageCore.Lark_Permission_CancelGrantButton
            }
        }
        return text
    }

    /// 自己发的消息时：shareStatus >= 2需要显示次特殊说明，覆盖permissionDesc()显示
    var shareStatusText: String {
        var text = ""
        if self.shareStatus == 2 {
            // 本文档已开放所有人可编辑权限
            text = BundleI18n.LarkMessageCore.Lark_Docs_ChatDocsPermissionStatus2
        } else if self.shareStatus == 3 {
            // 本文档已开放所有人可阅读权限
            text = BundleI18n.LarkMessageCore.Lark_Docs_ChatDocsPermissionStatus3
        } else if self.shareStatus == 4 {
            // 本文档已开启组织内可编辑权限
            text = BundleI18n.LarkMessageCore.Lark_Docs_ChatDocsPermissionStatus4
        } else if self.shareStatus == 5 {
            // 本文档已开启组织内可阅读权限
            text = BundleI18n.LarkMessageCore.Lark_Docs_ChatDocsPermissionStatus5
        } else if self.shareStatus == 6 {
            // 你没有共享权限, 无法共享
            text = BundleI18n.LarkMessageCore.Lark_Docs_ChatDocsPermissionStatus6
        } else if self.shareStatus == 7 {
            // 你没有外部共享权限, 无法共享
            text = BundleI18n.LarkMessageCore.Lark_Docs_ChatDocsPermissionStatus7
        } else if self.shareStatus == 8 {
            // 本文档邀请人数已达上限
            text = BundleI18n.LarkMessageCore.Lark_Docs_ChatDocsPermissionStatus8
        } else if self.shareStatus == 9 {
            // 你没有访问权限，无法授权
            text = BundleI18n.LarkMessageCore.Lark_Docs_ChatDocsPermissionStatus9
        } else if self.shareStatus == 10 {
            // 文档包含敏感内容，请修改后共享
            text = BundleI18n.LarkMessageCore.Lark_Docs_ChatDocsPermissionStatus10
        } else if self.shareStatus == 11 {
            // 所属组织关闭了对外分享功能
            text = BundleI18n.LarkMessageCore.Lark_Docs_ChatDocsPermissionStatus11
        } else if self.shareStatus == 13 {
            // 文档所有者关闭了对外分享
            text = BundleI18n.LarkMessageCore.Lark_Docs_ChatDocsPermissionStatus13
        } else if self.shareStatus == 14 {
            // 该文档关闭了对外分享功能
            text = BundleI18n.LarkMessageCore.Lark_Docs_ChatDocsPermissionStatus14
        } else if self.shareStatus == 15 {
            // 所属知识空间关闭了对外分享功能
            text = BundleI18n.LarkMessageCore.Lark_Docs_ChatDocsPermissionStatus15
        } else {
            // 共享失败，请进入文档共享
            text = BundleI18n.LarkMessageCore.Lark_Docs_ShareDocs_DefaultInfo
        }
        return text
    }

    /// 自己发的消息时：是否能够修改权限
    var canSelectPermission: Bool {
        return self.docPermission?.optionalPermissions.count ?? 0 > 1
    }

    /// 自己发的消息时：箭头左侧文字，'可阅读'等
    func permissionText(chat: Chat) -> String? {
        var isGroup = false
        if chat.type == .group || chat.type == .topicGroup {
            isGroup = true
        }
        guard let permissions = self.docPermission?.optionalPermissions,
            let selectedIndex = self.docPermission?.selectedPermissionIndex,
            permissions.count > Int(selectedIndex) else {
                //如果没有optionalPermission的话就展示当前的userDocsPermissionStringValue
                return self.defaultTextForPermission(isGroup: isGroup)
        }

        docPreviewLogger.info("docPreview permissionText messageID:\(self.id) selectedPermissionIndex:\(selectedIndex)")
        // 群聊和单聊 根据UX的要求 需要展示不同的权限文案
        if isGroup {
            return permissions[Int(selectedIndex)].displayNameWithPermissionType(.thirdPersonPlural)
        } else {
            return permissions[Int(selectedIndex)].displayNameWithPermissionType(.thirdPerson)
        }
    }

    /// 默认的返回文案
    /// - Parameter isGroup: 是否群聊
    /// - Returns: 当前的文案
    func defaultTextForPermission(isGroup: Bool) -> String? {
        if isGroup {
            return self.self.docPermission?.docsPermissionStringValueWith(permissionType: .thirdPersonPlural)
        }
        return self.self.docPermission?.docsPermissionStringValueWith(permissionType: .thirdPerson)
    }

    /// 别人发的消息时显示：你没有访问权限/你'可阅读'等
    var shareText: String {
        let permission = self.docPermission?.docsPermissionStringValueWith(permissionType: .secondPerson) ?? ""
        docPreviewLogger.info("docPreview shareText permission:\(permission) meesageId:\(self.id)")
        if permission.isEmpty {
            return BundleI18n.LarkMessageCore.Lark_Docs_ShareDocsNoPermission
        } else {
            return BundleI18n.LarkMessageCore.Lark_Docs_ShareDocsPermission(permission)
        }
    }
}

public extension Message {
    /// 当前要预览的Doc图标
    var docIcon: UIImage? {
        if let doc = self.doc {
            return LarkCoreUtils.docIcon(docType: doc.type, fileName: doc.name)
        }
        return nil
    }

    /// 当前要预览的Doc标题
    var docTitle: String {
        return self.doc?.name ?? ""
    }

    /// 当前要预览的Doc作者
    var docOwner: String {
        return BundleI18n.LarkMessageCore.Lark_Legacy_DocsPreviewOwner(self.doc?.ownerName ?? "")
    }

    /// 是否有Doc预览，只有一个Doc才显示预览，多个相同的Doc算一个
    func hasDocsPreview(currentChatterId: String) -> Bool {
        guard self.doc != nil, self.docs?.count == 1 else { return false }

        if let permission = self.docPermission {
            var docsPreviewEnable: Bool = false
            if currentChatterId == self.fromId {
                docsPreviewEnable = permission.shouldRender
            } else {
                docsPreviewEnable = true
            }
            if permission.shareStatus > 1 || docsPreviewEnable {
                docPreviewLogger.info("show DocsPreview.meesageId is:\(self.id)")
                return true
            }
        }
        docPreviewLogger.info("shareStatus:\(self.docPermission?.shareStatus),messageID:\(self.id)")
        return false
    }

    /// 内容本身是否只是一个DocLink
    func onlyHasDocLink() -> Bool {
        guard let doc = self.doc else { return false }

        /// 内容
        func richText() -> RustPB.Basic_V1_RichText? {
            if let content = self.content as? TextContent {
                return content.richText
            }
            if let content = self.content as? PostContent {
                return content.richText
            }
            return nil
        }

        guard let richText = richText(), let urlPreview = previewUrls.first(where: { (content) -> Bool in
            //有些情况下content.url(或doc.url)尾部会被加入#
            return content.url.hasPrefix(doc.url) || doc.url.hasPrefix(content.url)
        }) else { return false }
        var leafs: [RustPB.Basic_V1_RichTextElement] = []
        parseRichText(elements: richText.elements, elementIds: richText.elementIds, leafs: &leafs)
        return leafs.count == 1 && leafs.first?.property.anchor.content ?? "" == urlPreview.url
    }
}
