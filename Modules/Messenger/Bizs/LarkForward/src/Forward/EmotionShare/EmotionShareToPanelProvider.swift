//
//  EmotionShareToPanelProvider.swift
//  LarkForward
//
//  Created by JackZhao on 2021/5/13.
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
import LarkNavigation
import RustPB

struct EmotionShareToPanelContent: ForwardAlertContent {
    let stickerSet: RustPB.Im_V1_StickerSet
}

final class EmotionShareToPanelProvider: ForwardAlertProvider {
    // MARK: - override
    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? EmotionShareToPanelContent != nil {
            return true
        }
        return false
    }

    override var isSupportMention: Bool {
        return true
    }

    private lazy var forwardService = {
        try? resolver.resolve(assert: ForwardService.self)
    }()

    override var isSupportMultiSelectMode: Bool {
        return false
    }

    override func isShowInputView(by items: [ForwardItem]) -> Bool {
        return false
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        return nil
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let forwardService = self.forwardService else { return .just([]) }
        let ids = itemsToIds(items)
        return forwardService.checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds)
            .observeOn(MainScheduler.instance)
            .map({ [weak self] (chats) -> [String] in
                guard let chat = chats.first else { return [] }
                self?.dimissToRootVcAndPushNewChat(chat: chat)
                return []
            })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let forwardService = self.forwardService else { return .just([]) }
        let ids = itemsToIds(items)
        return forwardService.checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds)
            .observeOn(MainScheduler.instance)
            .map({ [weak self] (chats) -> [String] in
                guard let chat = chats.first else { return [] }
                self?.dimissToRootVcAndPushNewChat(chat: chat)
                return []
            })
    }

    func dimissToRootVcAndPushNewChat(chat: Chat) {
        // 产品要求做成至少和微信一样,但是这里这里牵涉了好几个vc的跳转,暂时没找到很好的效果
        let rootVC = RootNavigationController.shared
        let body = ChatControllerByChatBody(
            chat: chat,
            fromWhere: .feed,
            keyboardStartupState: KeyboardStartupState(
                type: .stickerSet,
                info: (self.content as? EmotionShareToPanelContent)?.stickerSet.stickerSetID ?? ""
            )
        )
        let topMost = WindowTopMostFrom(vc: rootVC)
        let navigator = self.userResolver.navigator
        rootVC.dismiss(animated: false) {
            _ = rootVC.popToRootViewController(animated: false)
            navigator.push(body: body, from: topMost, animated: false)
        }
    }
}
