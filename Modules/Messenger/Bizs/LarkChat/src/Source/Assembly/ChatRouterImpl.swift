//
//  ChatDelegate.swift
//  Lark
//
//  Created by K3 on 2018/7/26.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkContainer
import LarkModel
import LarkUIKit
import RxSwift
import RxCocoa
import LarkCore
import Swinject
import Photos
import EENavigator
import LarkIMMention
import LarkKeyboardView
import LarkAttachmentUploader
import LarkMessageCore
import LarkMessageBase
import LarkSDKInterface
import LarkMessengerInterface
import LarkAlertController
import LKCommonsLogging
import LarkFeatureGating
import RustPB
import LarkBaseKeyboard
import LarkChatOpenKeyboard

final class ChatRouterImpl: UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(ChatRouterImpl.self, category: "LarkChat.ChatRouterImpl")
    var completeTask: (([IMMentionOptionType]) -> Void)?
    var cancelTask: (() -> Void)?

    var rootVCBlock: (() -> UIViewController?)?

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }
}

extension ChatRouterImpl: ComposePostRouter {
    // 使用通用mention组件
    private var mentionOptEnable: Bool {
        userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "messenger.message.corporate_aite_clouddocuments"))
    }
    func presentAtPicker(
        chat: Chat,
        allowAtAll: Bool,
        allowMyAI: Bool,
        allowSideIndex: Bool,
        cancel: (() -> Void)?,
        complete: (([InputKeyboardAtItem]) -> Void)?
    ) {
        guard let from = self.rootVCBlock?() else {
            assertionFailure()
            return
        }
        if self.mentionOptEnable {
            // chat富文本键盘点击@
            let mentionChatModel = IMMentionChatConfig(id: chat.id,
                                                       userCount: chat.userCount,
                                                       isEnableAtAll: (chat.isEnableAtAll(me: userResolver.userID) && allowAtAll),
                                                       showChatUserCount: chat.isUserCountVisible)
            let panel = IMMentionPanel(resolver: self.userResolver, mentionChatModel: mentionChatModel)
            panel.delegate = self
            self.cancelTask = cancel
            self.completeTask = { items in
                complete?(items.compactMap { item -> InputKeyboardAtItem? in
                    switch item.type {
                    case .chatter:
                        guard (item.id?.isEmpty == false) && (item.name != nil) else {
                            Self.logger.info("presentAtPicker selectItem chatter data error")
                            return nil
                        }
                        return .chatter(.init(id: item.id ?? "", name: item.name?.string ?? "", actualName: item.actualName ?? "", isOuter: !item.isInChat))
                    case .wiki:
                        if case .wiki(let info) = item.meta {
                            return .wiki(info.url, item.name?.string ?? "", info.type)
                        }
                        Self.logger.info("inputTextViewInputAt selectItem wiki data error")
                        return nil
                    case .document:
                        if case .doc(let info) = item.meta {
                            return .doc(info.url, item.name?.string ?? "", info.type)
                        }
                        Self.logger.info("inputTextViewInputAt selectItem doc data error")
                        return nil
                    case .unknown:
                        Self.logger.info("inputTextViewInputAt selectItem unknown")
                        return nil
                    case .chat:
                        Self.logger.info("inputTextViewInputAt selectItem chat will support")
                        assertionFailure("will support")
                        return nil
                    }
                })
            }
            panel.show(from: from)
        } else {
            var body = AtPickerBody(chatID: chat.id)
            body.cancel = cancel
            body.completion = { items in
                complete?(items.map { .chatter(.init(id: $0.id, name: $0.name, actualName: $0.actualName, isOuter: $0.isOuter)) })
            }
            body.allowAtAll = allowAtAll
            body.allowMyAI = allowMyAI
            body.allowSideIndex = allowSideIndex
            navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: from,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.autoAdaptStyle() }
            )
        }
    }

    func pushProfile(chatterId: String) {
        guard let from = self.rootVCBlock?() else {
            assertionFailure()
            return
        }
        let body = PersonCardBody(chatterId: chatterId)
        navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }
}

extension ChatRouterImpl: IMMentionPanelDelegate {
    func panel(didFinishWith items: [IMMentionOptionType]) {
        self.completeTask?(items)
    }

    func panelDidCancel() {
        self.cancelTask?()
    }
}

extension ChatRouterImpl: GroupCardJoinRouter {
    func pushPersonCard(chatter: Chatter, chatId: String) {
        if chatter.type == .bot {
            return
        }
        guard let from = self.rootVCBlock?() else {
            assertionFailure()
            return
        }
        let body = PersonCardBody(chatterId: chatter.id,
                                  chatId: chatId,
                                  source: .chat)
        if Display.phone {
            navigator.push(body: body, from: from)
        } else {
            navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: from,
                prepare: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        }
    }

    func pushChatController(chatId: String) {
        guard let from = self.rootVCBlock?() else {
            assertionFailure()
            return
        }
        let body = ChatControllerByIdBody(chatId: chatId, fromWhere: .card)
        navigator.push(body: body, from: from)
    }

    func presentPreviewImageController(asset: LKDisplayAsset, shouldDetectFile: Bool) {
        guard let from = self.rootVCBlock?() else {
            assertionFailure()
            return
        }
        let body = PreviewImagesBody(
            assets: [asset.transform()],
            pageIndex: 0,
            scene: .normal(assetPositionMap: [:], chatId: nil),
            shouldDetectFile: shouldDetectFile,
            canShareImage: false,
            canEditImage: false,
            hideSavePhotoBut: true,
            canTranslate: userResolver.fg.staticFeatureGatingValue(with: .init(key: .imageViewerInOtherScenesTranslateEnable)),
            translateEntityContext: (nil, .other)
        )
        navigator.present(body: body, from: from)
    }
}

extension ChatRouterImpl: NormalChatKeyboardRouter {
    func showImagePicker(
        showOriginButton: Bool,
        selectedBlock: ((ImagePickerViewController, _ assets: [PHAsset], _ isOriginalImage: Bool) -> Void)?
    ) {
        guard let from = self.rootVCBlock?() else {
            assertionFailure()
            return
        }
        let picker = ImagePickerViewController(assetType: .imageOnly(maxCount: 9),
                                               isOriginButtonHidden: !showOriginButton,
                                               sendButtonTitle: BundleI18n.LarkChat.Lark_Legacy_LarkConfirm)
        picker.showMultiSelectAssetGridViewController()
        picker.imagePikcerCancelSelect = { (picker, _) in
            picker.dismiss(animated: true, completion: nil)
        }
        picker.imagePickerFinishSelect = { (picker, result) in
            selectedBlock?(picker, result.selectedAssets, result.isOriginal)
        }
        picker.imageEditAction = { ChatTracker.trackImageEditEvent($0.event, params: $0.params) }
        picker.modalPresentationStyle = .fullScreen
        navigator.present(picker, from: from)
    }

    func showStickerSetSetting() {
        guard let from = self.rootVCBlock?() else {
            assertionFailure()
            return
        }
        navigator.present(
            body: EmotionSettingBody(showType: .present),
            wrap: LkNavigationController.self,
            from: from,
            prepare: { $0.modalPresentationStyle = .fullScreen }
        )
        ChatTracker.trackEmotionSettingShow(from: .fromPannel)
    }

    func showStickerSetting() {
        guard let from = self.rootVCBlock?() else {
            assertionFailure()
            return
        }
        navigator.present(
            body: StickerManagerBody(showType: .present),
            wrap: LkNavigationController.self,
            from: from,
            prepare: { $0.modalPresentationStyle = .fullScreen }
        )
    }

    // swiftlint:disable function_parameter_count
    func showComposePostView(
        chat: Chat,
        dataService: KeyboardShareDataService,
        richTextInfoItem: RichTextInfoItem?,
        placeholder: NSAttributedString?,
        reeditContent: RichTextContent?,
        postItem: ComposePostItem?,
        postServiceItem: PostServiceItem,
        supportRealTimeTranslate: Bool,
        pasteBoardToken: String,
        callbacks: ShowComposePostViewCallBacks,
        chatFromWhere: ChatFromWhere) {
            // swiftlint:enable function_parameter_count
            guard let from = self.rootVCBlock?() else {
                assertionFailure()
                return
            }
            var body = ComposePostBody(chat: chat,
                                       pasteBoardToken: pasteBoardToken,
                                       dataService: dataService,
                                       chatFromWhere: chatFromWhere)
            body.defaultContent = richTextInfoItem?.richTextStr
            body.userActualNameInfoDic = richTextInfoItem?.userActualNameInfoDic
            body.placeholder = placeholder
            body.reeditContent = reeditContent
            body.postItem = postItem
            body.callbacks = callbacks
            body.attachmentServer = postServiceItem.attachmentServer
            body.translateService = postServiceItem.translateService
            body.sendVideoEnable = true
            body.supportRealTimeTranslate = supportRealTimeTranslate
            navigator.present(body: body, from: from, animated: false) { _, res in
                if let err = res.error {
                    Self.logger.error("showComposePostView error to present chatId: \(chat.id)", error: err)
                }
            }
        }
}
