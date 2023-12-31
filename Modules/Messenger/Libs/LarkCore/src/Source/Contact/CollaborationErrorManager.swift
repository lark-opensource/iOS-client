//
//  CollaborationErrorManager.swift
//  LarkCore
//
//  Created by JackZhao on 2020/10/29.
//

import UIKit
import Foundation
import EENavigator
import LarkModel
import UniverseDesignToast
import LarkMessengerInterface
import LarkSDKInterface
import ByteWebImage

public enum CollaborationError: Error, Equatable {
    case collaborationBeBlocked  // 被屏蔽
    case collaborationBlocked // 主动屏蔽
    case collaborationNoRights // 无权限
    case otherError
}

public struct CollaborationUserMeta {
    public var chatId: String
    public var chatterId: String
    public var chatterName: String
    public var chatterAvatarKey: String

    public init(chatId: String,
                chatterId: String,
                chatterName: String,
                chatterAvatarKey: String) {
        self.chatId = chatId
        self.chatterId = chatterId
        self.chatterName = chatterName
        self.chatterAvatarKey = chatterAvatarKey
    }
}

public final class CollaborationErrorManager {
    public static func processPushStartSingleMeetingVCError(
        navigator: Navigatable,
        meta: CollaborationUserMeta,
        error: CollaborationError?,
        from: UIViewController
    ) {
        guard let error = error,
            !meta.chatterName.isEmpty,
            !meta.chatterAvatarKey.isEmpty else {
            return
        }
        switch error {
        case .collaborationBlocked:
            if let window = from.view.window {
                UDToast.showFailure(with: BundleI18n.LarkCore.View_G_NoPermissionsToCallBlocked, on: window, error: error)
            }
        case .collaborationBeBlocked:
            if let window = from.view.window {
                UDToast.showFailure(with: BundleI18n.LarkCore.View_G_NoPermissionsToCall, on: window, error: error)
            }
        case .collaborationNoRights: Self.presentToAddContactAlert(
            navigator: navigator,
            userId: meta.chatterId,
            chatId: meta.chatId,
            displayName: meta.chatterName,
            from: from)
        default:
            break
        }
    }

    // 跳转到加好友弹窗
    private static func presentToAddContactAlert(
        navigator: Navigatable,
        userId: String,
        chatId: String,
        displayName: String,
        from: UIViewController
    ) {
        var source = Source()
        source.sourceType = .chat
        source.sourceID = chatId
        let addContactBody = AddContactApplicationAlertBody(userId: userId,
                                                            chatId: chatId,
                                                            source: source,
                                                            displayName: displayName,
                                                            businessType: .chatVCConfirm)
        navigator.present(body: addContactBody, from: from)
    }
}

public final class AttachmentImageError {
    public static func getCompressError(error: CompressError) -> String? {
        switch error {
        case .imageFileSizeExceeded(let limitFileSize):
            let mb = Int(limitFileSize / 1024 / 1024)
            return BundleI18n.LarkCore.Lark_IM_ImageSizeTooLarge_Toast(mb)
        case .imagePixelsExceeded(let limitImageSize):
            return BundleI18n.LarkCore.Lark_IM_ImageTooClear_Toast("\(limitImageSize.width) * \(limitImageSize.height)")
        case .fileTypeInvalid:
            return BundleI18n.LarkCore.Lark_IM_InvalidImageFormat_Toast
        default:
            return nil
        }
    }
}
