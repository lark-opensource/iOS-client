//
//  ThreadChatRouter.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/2/14.
//

import UIKit
import Foundation
import EENavigator
import Photos
import LarkModel
import LarkUIKit
import LarkMessageCore
import LarkMessengerInterface
import LarkAssetsBrowser
import LarkContainer
import LarkFeatureGating
import LarkSDKInterface

protocol ThreadChatRouter {
    func presentPostView(chat: Chat, isDefaultTopicGroup: Bool, multiEditingMessage: Message?, from vc: UIViewController)
}

final class ThreadChatRouterImpl: ThreadChatRouter, UserResolverWrapper {
    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    /// 小组发帖
    func presentPostView(chat: Chat,
                         isDefaultTopicGroup: Bool,
                         multiEditingMessage: Message?,
                         from vc: UIViewController) {
        let body = ThreadChatComposePostBody(
            chat: chat,
            isDefaultTopicGroup: isDefaultTopicGroup,
            pasteBoardToken: "LARK-PSDA-messenger-thread-chat-send-post-copy-permission",
            multiEditingMessage: multiEditingMessage
        )
        navigator.present(body: body, from: vc, animated: !Display.pad)
    }
}

extension ThreadChatRouterImpl: ThreadKeyboardRouter {
    func showImagePicker(
        showOriginButton: Bool,
        from vc: UIViewController,
        selectedBlock: ((ImagePickerViewController, _ assets: [PHAsset], _ isOriginalImage: Bool) -> Void)?
        ) {
        let picker = ImagePickerViewController(assetType: .imageOnly(maxCount: 9),
                                                   isOriginButtonHidden: !showOriginButton,
                                                   sendButtonTitle: BundleI18n.LarkThread.Lark_Legacy_LarkConfirm)
        picker.showMultiSelectAssetGridViewController()
        picker.imagePikcerCancelSelect = { (picker, _) in
            picker.dismiss(animated: true, completion: nil)
        }
        picker.imagePickerFinishSelect = { (picker, result) in
            selectedBlock?(picker, result.selectedAssets, result.isOriginal)
        }

        picker.imageEditAction = { StickerTracker.trackImageEditEvent($0.event, params: $0.params) }
        picker.modalPresentationStyle = .fullScreen
        navigator.present(picker, from: vc)
    }

    func showStickerSetting(from vc: UIViewController) {
        navigator.present(body: EmotionSettingBody(showType: .present),
                                 wrap: LkNavigationController.self,
                                 from: vc,
                                 prepare: { $0.modalPresentationStyle = .fullScreen })
        ThreadTracker.trackEmotionSettingShow(from: .fromPannel)
    }
}
