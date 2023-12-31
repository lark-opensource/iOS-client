//
//  DriveCommentFooterAdapter.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/3/25.
//  

import Foundation
import EENavigator
import LarkLocalizations
import SKCommon
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignDialog
import SpaceInterface

extension DriveCommentAdapter {
  
    
    private func showFailToast(_ code: Int?, commentContext: CommentAdaptContext) {
        if code == DocsNetworkError.Code.reportError.rawValue || code == DocsNetworkError.Code.auditError.rawValue {
            commentContext.showSuccess(BundleI18n.SKResource.Doc_Review_Fail_Notify_Member())
        } else {
            commentContext.showFailed(BundleI18n.SKResource.Doc_Doc_CommentSendFailed)
        }
    }

    private func showNotNotifyToastIfNeeded(_ entities: CommentEntities?) {
        guard let notNotifyUsers = entities?.notNotifyUsers, !notNotifyUsers.isEmpty else { return }
        // 确认下怎么触发
        guard let rootVC = hostController?.view.window?.rootViewController,
              let from = UIViewController.docs.topMost(of: rootVC) else {
            spaceAssertionFailure("showNotNotifyToastIfNeeded cannot find from vc")
            return
        }
        let separator = LanguageManager.currentLanguage == .en_US ? "," : "、"
        let names = notNotifyUsers.map { $0.name }.joined(separator: separator)
        let dialog = UDDialog()
        dialog.setContent(text: BundleI18n.SKResource.Doc_Permission_NotNotifyUser(names))
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm)
        Navigator.shared.present(dialog, from: from)
    }

    private func _constructComment(_ commentContext: CommentAdaptContext, content: CommentContent) -> MountComment {
        let commentID = commentContext.currentCommentID
        let mountNodePoint = (type: fileType, token: fileToken)
        let focusType = commentContext.atInputFocusType
        let atInputTextType = commentContext.atInputTextType

        let info = MountCommentInfo(type: atInputTextType,
                                                   focusType: focusType,
                                                   mountNodePoint: mountNodePoint,
                                                   commentID: commentID,
                                                   replyID: nil)
        
        return MountComment(content: content, info: info)
    }

}
