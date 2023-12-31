//
//  EmotionShareProvider.swift
//  LarkForward
//
//  Created by huangjianming on 2019/8/20.
//

import UIKit
import Foundation
import RxSwift
import UniverseDesignToast
import LarkModel
import LarkSDKInterface
import LarkMessengerInterface
import LarkAlertController
import EENavigator
import RustPB

struct EmotionShareAlertContent: ForwardAlertContent {
    let stickerSet: RustPB.Im_V1_StickerSet
}

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
final class EmotionShareProvider: ForwardAlertProvider {

    override var isSupportMention: Bool {
        return true
    }

    // MARK: - override
    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? EmotionShareAlertContent != nil {
            return true
        }
        return false
    }

    override var isSupportMultiSelectMode: Bool {
        return false
    }

    override func isShowInputView(by items: [ForwardItem]) -> Bool {
        return false
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let content = content as? EmotionShareAlertContent else { return nil }
        let label = UILabel()
        label.text = "[" + BundleI18n.LarkForward.Lark_Chat_StickerPackDescription + "]" + content.stickerSet.title
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N600
        return label
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        guard let content = content as? EmotionShareAlertContent else { return nil }
        let includeConfigs: IncludeConfigs = [
            //业务需要置灰帖子
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(),
            ForwardBotEnabledEntityConfig()
        ]
        return includeConfigs
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        let ids = itemsToIds(items)

        guard let content = content as? EmotionShareAlertContent,
              let window = from.view.window else {
            return .just([])
        }
        let hud = UDToast.showLoading(on: window)
        return self.checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds).flatMap({ [weak self] (chats) -> Observable<[String]> in
            guard let self = self, let chat = chats.first else { return Observable.empty() }
            Tracer.trackStickerSetForward()

            let stickerService = try self.resolver.resolve(assert: StickerService.self)
            return stickerService.sendShareStickerSet(
                stickerSetID: content.stickerSet.stickerSetID,
                chatID: chat.id
            ).map({ (_) -> [String] in
                return [chat.id]
            })
        })
        .observeOn(MainScheduler.instance)
        .do(onNext: { (_) in
            hud.remove()
        }, onError: { [weak self] (error) in
            guard let self = self else { return }
            forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
        })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        let ids = itemsToIds(items)

        guard let content = content as? EmotionShareAlertContent,
              let window = from.view.window else {
            return .just([])
        }
        let hud = UDToast.showLoading(on: window)
        return self.checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds).flatMap({ [weak self] (chats) -> Observable<[String]> in
            guard let self = self, let chat = chats.first else { return Observable.empty() }
            Tracer.trackStickerSetForward()

            let stickerService = try self.resolver.resolve(assert: StickerService.self)
            return stickerService.sendShareStickerSet(
                stickerSetID: content.stickerSet.stickerSetID,
                chatID: chat.id
            ).map({ (_) -> [String] in
                return [chat.id]
            })
        })
        .observeOn(MainScheduler.instance)
        .do(onNext: { (_) in
            hud.remove()
        }, onError: { [weak self] (error) in
            guard let self = self else { return }
            forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
        })
    }
}
