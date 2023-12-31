//
//  CommentReactionModel.swift
//  SKCommon
//
//  Created by huayufan on 2023/1/30.
//  


import UIKit
import UniverseDesignIcon
import SKResource
import LarkReactionView
import LarkMenuController
import LarkReactionDetailController
import SKCommon

enum CommentAbility: String {
    case edit = "ReactionPanelEDIT"
    case delete = "icon_global_delete_nor"
    case resolve = "ReactionPanelRESOLVE"
    case translate = "ReactionPanelTRANSLATE"
    case copy = "icon_tool_copy_nor"
    case showOriginContent = "ReactionPanelSHOWORIGINCONTENT"// 原文
    case reply = "comment_reply"
    case closseTranslation = "closseTranslation"// 收起译文
    case copyAnchorLink
    case shareAnchorLink

    var udImage: UIImage {
        switch self {
        case .delete:
            return UDIcon.deleteTrashOutlined
        case .edit:
            return UDIcon.editOutlined
        case .translate, .closseTranslation, .showOriginContent:
            return UDIcon.translateOutlined
        case .copy:
            return UDIcon.copyOutlined
        case .resolve:
            return UDIcon.yesOutlined
        case .reply:
            if DocsSDK.currentLanguage == .zh_CN {
                return UDIcon.replyCnOutlined
            } else {
                return UDIcon.replyOutlined
            }
        case .copyAnchorLink:
            return UDIcon.linkCopyOutlined
        case .shareAnchorLink:
            return UDIcon.shareOutlined
        }
    }

    var description: String {
        switch self {
        case .edit:
            return BundleI18n.SKResource.Doc_Facade_Edit
        case .delete:
            return BundleI18n.SKResource.Doc_Facade_Delete
        case .resolve:
            return BundleI18n.SKResource.LarkCCM_Mobile_Comments_Resolve_Tooltip
        case .translate:
            return BundleI18n.SKResource.Doc_Comment_Translate_Str
        case .copy:
            return BundleI18n.SKResource.Doc_Doc_Copy
        case .showOriginContent:
            return BundleI18n.SKResource.Doc_Translate_OrignalTitle
        case .reply:
            return BundleI18n.SKResource.Doc_Comment_Reaction_Reply
        case .closseTranslation:
            return BundleI18n.SKResource.Doc_Comment_PackUpTranslation
        case .copyAnchorLink:
            return BundleI18n.SKResource.LarkCCM_Docs_CopyLink_Button_Mob
        case .shareAnchorLink:
            return BundleI18n.SKResource.LarkCCM_DocxIM_Forward_Button
        }
    }
}

class MenuViewModel: SimpleMenuViewModel {
    public override func update(rect: CGRect, info: MenuLayoutInfo, isFirstTime: Bool) {
        if isFirstTime {
            // 更新 reactin bar 位置 方式2
            var reactionBatAtTop: Bool = true
            if let location = info.transformTrigerLocation() {
                reactionBatAtTop = location.y < rect.origin.y
            } else if let locationRect = info.transformTrigerView() {
                reactionBatAtTop = locationRect.origin.y < rect.origin.y
            }
            self.menuBar.reactionBarAtTop = reactionBatAtTop
        }
    }
}
