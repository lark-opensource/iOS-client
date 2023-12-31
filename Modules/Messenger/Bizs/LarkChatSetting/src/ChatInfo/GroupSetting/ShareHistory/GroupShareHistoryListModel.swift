//
//  GroupShareHistoryListModel.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/8/2.
//

import UIKit
import Foundation
import LarkModel
import RustPB

enum GroupShareHistoryTarget {
    /// 没有明确的Target，比如群二维码
    case none

    /// 分享到人
    case chatter(id: String, name: String)

    /// 分享到群，单聊定义为 chatter
    case chat(id: String, name: String)

    /// 分享到Doc
    case doc(url: String, name: String, type: RustPB.Basic_V1_Doc.TypeEnum, isUnauthorized: Bool)

    /// 列表显示信息
    var dispalyMessage: String? {
        switch self {
        case .none: return nil
        case .chat(_, let name): return name
        case .chatter(_, let name): return name
        case .doc(_, let name, _, let isUnauthorized):
            return isUnauthorized ? BundleI18n.LarkChatSetting.Lark_Group_UnauthorizedDoc : name
        }
    }

    /// icon,目前仅Doc类型有
    var icon: UIImage? {
        if case .doc(_, _, let type, _) = self {
            switch type {
            case .doc:
                return Resources.chat_setting_doc_word
            case .sheet:
                return Resources.chat_setting_doc_sheet
            case .unknown, .bitable, .mindnote, .file, .slide, .wiki, .docx, .folder, .catalog, .slides, .shortcut:
                return nil
            @unknown default:
                assert(false, "new value")
                return nil
            }
        }
        return nil
    }
}

struct GroupShareHistoryListItem {
    var id: String // 分享ID
    var token: String // 分享Token
    var type: RustPB.Basic_V1_ChatShareInfo.ShareType // 分享类型：卡片、二维码、Doca卡片
    var sharerID: String // 分享者 ID
    var avatarKey: String // 分享者头像Key
    var name: String // 分享者名字
    var way: String // 分享方式描述
    var target: GroupShareHistoryTarget // 分享目标信息
    var time: Date // 分享创建时间
    var isVailed: Bool // 分享是否还有效
    var isShowBorderLine: Bool = true // 下划线
}

extension RustPB.Basic_V1_ChatShareInfo {

    private func shareTagertInfo(isTopicGroup: Bool) -> (way: String, GroupShareHistoryTarget) {
        let prefixInfo = isTopicGroup ? BundleI18n.LarkChatSetting.Lark_Groups_ShareHistoryCircleCardSharedByUser : BundleI18n.LarkChatSetting.Lark_Group_ShareInvitationToChatMobile
        switch self.targetType {
        case .unknownTargetType:
            return ("", .none)
        case .targetChat:
            return (prefixInfo, .chat(id: targetChatExtra.chatID, name: targetChatExtra.chatName))
        case .targetChatter:
            return (prefixInfo, .chatter(id: targetChatterExtra.chatterID, name: targetChatterExtra.name))
        case .targetQrcode:
            return (BundleI18n.LarkChatSetting.Lark_Group_CreateQRCodeMobile, .none)
        case .targetDoc:
            return (prefixInfo,
                    .doc(url: targetDocExtra.docURL,
                         name: targetDocExtra.docName,
                         type: targetDocExtra.docType,
                         isUnauthorized: targetDocExtra.unauthorized))
        case .targetLink:
            return (isTopicGroup ? BundleI18n.LarkChatSetting.Lark_Groups_ShareHistoryGeneratedCircleLink : BundleI18n.LarkChatSetting.Lark_Chat_CreatedShareLink, .none)
        @unknown default:
            assert(false, "new value")
            return ("", .none)
        }
    }

    func item(isTopicGroup: Bool) -> GroupShareHistoryListItem {
        let (way, target) = shareTagertInfo(isTopicGroup: isTopicGroup)
        return GroupShareHistoryListItem(
            id: self.id,
            token: self.token,
            type: self.type,
            sharerID: self.shareChatterExtra.shareChatterID,
            avatarKey: self.shareChatterExtra.avatarKey,
            name: self.shareChatterExtra.name,
            way: way,
            target: target,
            time: Date(timeIntervalSince1970: TimeInterval(self.createTime)),
            isVailed: self.status == .active)
    }
}
