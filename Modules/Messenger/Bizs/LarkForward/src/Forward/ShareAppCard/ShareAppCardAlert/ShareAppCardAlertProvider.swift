//
//  ShareAppCardAlertProvider.swift
//  LarkForward
//
//  Created by 姚启灏 on 2019/5/20.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import UniverseDesignToast
import LKCommonsLogging
import LarkSDKInterface
import LarkSendMessage
import LarkMessengerInterface
import RustPB
import LarkRichTextCore
import LarkBaseKeyboard

struct ShareAppCardAlertContent: ForwardAlertContent {
    let appShareType: ShareAppCardType
    let appUrl: String
    let callback: (([String: Any]?, Bool) -> Void)?
    var multiSelect: Bool?
    var customView: UIView?

    init(shareType: ShareAppCardType,
         appUrl: String,
         callback: (([String: Any]?, Bool) -> Void)?) {
        self.appShareType = shareType
        self.appUrl = appUrl
        self.callback = callback
    }
}

// nolint: duplicated_code,magic_number -- v2转发代码，v3转发全业务GA后可删除
final class ShareAppCardAlertProvider: ForwardAlertProvider {
    static let logger = Logger.log(ShareAppCardAlertProvider.self, category: "Module.IM.Share")
    let disposeBag = DisposeBag()
    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ShareAppCardAlertContent != nil {
            return true
        }
        return false
    }

    // 开启开放平台Mention能力
    override var isSupportMention: Bool {
        return true
    }

    /// 是否支持多选
    override var isSupportMultiSelectMode: Bool {
        guard let shareAppCardContent = content as? ShareAppCardAlertContent else { return false }
        return (shareAppCardContent.multiSelect == true)
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        guard let shareAppCardContent = self.content as? ShareAppCardAlertContent else { return nil }
        //小程序置灰话题
        let includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig(),
            ForwardBotEnabledEntityConfig(),
            ForwardMyAiEnabledEntityConfig()
        ]
        return includeConfigs
    }

    override func getForwardItemsIncludeConfigs() -> IncludeConfigs? {
        guard let shareAppCardContent = self.content as? ShareAppCardAlertContent else { return nil }
        let includeConfigs: IncludeConfigs = [
            ForwardUserEntityConfig(),
            ForwardGroupChatEntityConfig(),
            ForwardBotEntityConfig(),
            ForwardThreadEntityConfig(),
            ForwardMyAiEntityConfig()
        ]
        return includeConfigs
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        guard let shareAppCardContent = self.content as? ShareAppCardAlertContent, var limitedHightCustomView = shareAppCardContent.customView else { return nil }
        //对customView进行限高
        var height = limitedHightCustomView.constraints.first(where: {
            $0.firstAttribute == .height
        })?.constant
        guard let height = height else { return limitedHightCustomView }
        if height > 224 {
            limitedHightCustomView.snp.updateConstraints { make in
                make.height.equalTo(224)
            }
        }
        return limitedHightCustomView
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let shareAppCardContent = content as? ShareAppCardAlertContent,
              let sendMessageAPI = try? self.resolver.resolve(assert: SendMessageAPI.self),
              let window = from.view.window else { return .just([]) }

        var tracker = ShareAppreciableTracker(
            pageName: "ForwardViewController",
            fromType: transformToFromType(shareAppCardContent.appShareType)
        )
        tracker.start()
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let startTime = CACurrentMediaTime()

        return self.checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds)
            .flatMap { (chats) -> Observable<[String]> in
                let chatIds = chats.map({ $0.id })
                guard let chatId = chatIds.first else { return .just(chatIds) }
                return sendMessageAPI
                    .sendShareAppCardMessage(context: nil, type: shareAppCardContent.appShareType, chatId: chatId)
                .flatMap({ _ -> Observable<[String]> in
                    if let extraText = input, !extraText.isEmpty {
                        sendMessageAPI.sendText(
                            context: nil,
                            content: RustPB.Basic_V1_RichText.text(extraText),
                            parentMessage: nil,
                            chatId: chatId,
                            threadId: nil,
                            stateHandler: nil
                        )
                    }
                    return .just([chatId])
                })
            }.observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] (_) in
                hud.remove()
                tracker.end(sdkCost: CACurrentMediaTime() - startTime)
                self?.onSuccess(callback: shareAppCardContent.callback, items: items)
            }, onError: { (error) in
                if let error = error.underlyingError as? APIError {
                    switch error.type {
                    case .banned(let message):
                        hud.showFailure(with: message, on: window, error: error)
                    default:
                        hud.showFailure(
                            with: BundleI18n.LarkForward.Lark_Legacy_ShareFailed,
                            on: window,
                            error: error
                        )
                    }
                } else {
                    hud.showFailure(with: BundleI18n.LarkForward.Lark_Legacy_ShareFailed, on: window, error: error)
                }
                ShareAppCardAlertProvider.logger.error("content share failed", error: error)
                shareAppCardContent.callback?(nil, false)
                tracker.error(error)
            })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let shareAppCardContent = content as? ShareAppCardAlertContent,
              let sendMessageAPI = try? self.resolver.resolve(assert: SendMessageAPI.self),
              let window = from.view.window else { return .just([]) }

        var tracker = ShareAppreciableTracker(
            pageName: "ForwardViewController",
            fromType: transformToFromType(shareAppCardContent.appShareType)
        )
        tracker.start()
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let startTime = CACurrentMediaTime()

        return self.checkAndCreateChats(chatIds: ids.chatIds, userIds: ids.userIds)
            .flatMap { (chats) -> Observable<[String]> in
                let chatIds = chats.map({ $0.id })

                chatIds.forEach({ chatId in
                    sendMessageAPI.sendShareAppCardMessage(context: nil,
                                                           type: shareAppCardContent.appShareType,
                                                           chatId: chatId).subscribe(onNext: {
                        if let extraText = attributeInput, extraText.length != 0 {
                            if var richText = RichTextTransformKit.transformStringToRichText(string: extraText) {
                                richText.richTextVersion = 1
                                sendMessageAPI.sendText(context: nil,
                                                        content: richText,
                                                        parentMessage: nil,
                                                        chatId: chatId,
                                                        threadId: nil,
                                                        stateHandler: nil)
                            }
                        }
                    }, onError: { error in
                        ShareAppCardAlertProvider.logger.error("appCard share failed,chatId: \(chatId)", error: error)
                    })
                })
                return .just(chatIds)
            }.observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] (_) in
                hud.remove()
                tracker.end(sdkCost: CACurrentMediaTime() - startTime)
                self?.onSuccess(callback: shareAppCardContent.callback, items: items)
            }, onError: { (error) in
                if let error = error.underlyingError as? APIError {
                    switch error.type {
                    case .banned(let message):
                        hud.showFailure(with: message, on: window, error: error)
                    default:
                        hud.showFailure(
                            with: BundleI18n.LarkForward.Lark_Legacy_ShareFailed,
                            on: window,
                            error: error
                        )
                    }
                } else {
                    hud.showFailure(with: BundleI18n.LarkForward.Lark_Legacy_ShareFailed, on: window, error: error)
                }
                ShareAppCardAlertProvider.logger.error("reply text share failed", error: error)
                shareAppCardContent.callback?(nil, false)
                tracker.error(error)
            })
    }

    override func dismissAction() {
        guard let shareAppCardContent = content as? ShareAppCardAlertContent, let c = shareAppCardContent.callback else { return }
        c(nil, true)
    }

    private func onSuccess(callback: (([String: Any]?, Bool) -> Void)?,
                           items: [ForwardItem]) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let `self` = self, let c = callback else { return }
            var itemArr = [[String: Any]]()
            for item: ForwardItem in items {
                var p = [String: Any]()
                if item.type == .user || item.type == .bot {
                    p["type"] = item.type == .user ? 0 : 2
                    let semaphore = DispatchSemaphore(value: 0)
                    self.getChatId(userId: item.id) { (chatId: String?) in
                        semaphore.signal()
                        guard let c = chatId else {
                            return
                        }
                        p["chatid"] = c
                        itemArr.append(p)
                    }
                    semaphore.wait()
                } else if item.type == .chat {
                    p["type"] = 1
                    p["chatid"] = item.id
                    itemArr.append(p)
                }
            }
            DispatchQueue.main.async {
                c(["items": itemArr], false)
            }
        }
    }
    func getChatId(userId: String, cb: @escaping (String?) -> Void) {
        guard let chatService = try? self.resolver.resolve(assert: ChatService.self) else { return }
        chatService.createP2PChat(userId: userId, isCrypto: false, chatSource: nil)
            .subscribe(onNext: { (chat) in
                cb(chat.id)
            }, onError: { (_ err) in
                cb(nil)
            }).disposed(by: disposeBag)
    }

    @inline(__always)
    private func transformToFromType(_ shareAppCardType: ShareAppCardType) -> ShareAppreciableTracker.FromType {
        switch shareAppCardType {
        case .app:
            return .h5app
        case .appPage:
            return .h5app
        case .h5:
            return .web
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}
