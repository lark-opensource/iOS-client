//
//  ShareChatAlertProvider.swift
//  LarkForward
//
//  Created by 姚启灏 on 2019/4/2.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import UniverseDesignToast
import RxSwift
import LKCommonsLogging
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface
import LarkAlertController
import EENavigator
import LarkFeatureGating
import Swinject
import LarkContainer

struct ShareChatAlertContent: ForwardAlertContent {
    let fromChat: Chat
    var getForwardContentCallback: GetForwardContentCallback {
        let param = SendGroupCardForwardParam(shareChatId: self.fromChat.id)
        let forwardContent = ForwardContentParam.sendGroupCardMessage(param: param)
        let callback = {
            let observable = Observable.just(forwardContent)
            return observable
        }
        return callback
    }

    init(fromChat: Chat) {
        self.fromChat = fromChat
    }
}

// nolint: duplicated_code -- v2转发代码，v3转发全业务GA后可删除
final class ShareChatAlertProvider: ForwardAlertProvider {
    static let logger = Logger.log(ShareChatAlertProvider.self, category: "Module.IM.Share")
    public var currentChatterId: String {
        return self.resolver.userID
    }

    override var isSupportMention: Bool {
        return true
    }
    required init(userResolver: UserResolver, content: ForwardAlertContent) {
        super.init(userResolver: userResolver, content: content)
        var filterParam = ForwardFilterParameters()
        filterParam.includeThread = true
        self.filterParameters = filterParam
    }
    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ShareChatAlertContent != nil {
            return true
        }
        return false
    }

    override func getFilter() -> ForwardDataFilter? {
        // 内部群 -> 内部群
        // 外部群 -> 内部群 + 外部群（FG控制）
        guard let messageContent = content as? ShareChatAlertContent else { return { return !$0.isCrossTenant } }

        if messageContent.fromChat.isCrossTenant {
            return { [weak self] in
                guard let self = self else { return !$0.isCrossTenant }
                return true
            }
        }
        return { return !$0.isCrossTenant }
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        // 内部群 -> 内部, 话题暂时无法判断内外部信息，都置灰，待确认
        // 外部群 -> 内部 + 外部
        guard let messageContent = content as? ShareChatAlertContent else { return nil }
        var isCrossTenantGroupChat = messageContent.fromChat.isCrossTenant
        var includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(tenant: isCrossTenantGroupChat ? .all : .inner),
            ForwardGroupChatEnabledEntityConfig(tenant: isCrossTenantGroupChat ? .all : .inner),
            ForwardBotEnabledEntityConfig()
        ]
        if isCrossTenantGroupChat { includeConfigs.append(ForwardThreadEnabledEntityConfig()) }
        return includeConfigs
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? ShareChatAlertContent,
              let forwardService = try? self.userResolver.resolve(assert: ForwardService.self),
              let window = from.view.window else { return .just([]) }

        var tracker = ShareAppreciableTracker(pageName: "ForwardViewController", fromType: .groupCard)
        tracker.start()
        let chat = messageContent.fromChat
        Tracer.trackChatConfigShareConfirmed(isExternal: chat.isCrossTenant, isPublic: chat.isPublic)
        Tracer.trackMergeForwardConfirm()

        let chatId = chat.id
        let ids = self.itemsToIds(items)
        let hud = UDToast.showLoading(on: window)
        let startTime = CACurrentMediaTime()
        let isAdmin = currentChatterId == chat.ownerId
        Tracer.trackImChatSettingChatForwardClick(chatId: chatId,
                                                   isAdmin: isAdmin,
                                                   chatCount: items.count,
                                                   msgCount: input?.count ?? 0,
                                                   isMsg: !(input?.isEmpty ?? true))
        return forwardService
                    .share(
                        chat: chat,
                        message: input ?? "",
                        to: ids.chatIds,
                        userIds: ids.userIds
                    )
                    .observeOn(MainScheduler.instance)
                    .do(onNext: { (_) in
                        hud.remove()
                        tracker.end(sdkCost: CACurrentMediaTime() - startTime)
                    }, onError: { [weak self] (error) in
                        guard let self = self else { return }
                        forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
                        tracker.error(error)
                        ShareChatAlertProvider.logger.error("share group card failed",
                                                            additionalData: ["chatId": chatId],
                                                            error: error)
                    })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let messageContent = content as? ShareChatAlertContent,
              let forwardService = try? self.userResolver.resolve(assert: ForwardService.self),
              let window = from.view.window else { return .just([]) }

        var tracker = ShareAppreciableTracker(pageName: "ForwardViewController", fromType: .groupCard)
        tracker.start()
        let chat = messageContent.fromChat
        Tracer.trackChatConfigShareConfirmed(isExternal: chat.isCrossTenant, isPublic: chat.isPublic)
        Tracer.trackMergeForwardConfirm()

        let chatId = chat.id
        let ids = self.itemsToIdsAndDic(items)
        let hud = UDToast.showLoading(on: window)
        let startTime = CACurrentMediaTime()
        let isAdmin = currentChatterId == chat.ownerId
        Tracer.trackImChatSettingChatForwardClick(chatId: chatId,
                                                   isAdmin: isAdmin,
                                                   chatCount: items.count,
                                                  msgCount: attributeInput?.string.count ?? 0,
                                                   isMsg: (attributeInput?.length != 0) ?? true)
        return forwardService
                    .share(
                        chat: chat,
                        attributeMessage: attributeInput ?? NSAttributedString(string: ""),
                        threadMessageIdDic: ids.threadMessageIdDic,
                        to: ids.chatIds,
                        userIds: ids.userIds
                    )
                    .observeOn(MainScheduler.instance)
                    .do(onNext: { (_) in
                        hud.remove()
                        tracker.end(sdkCost: CACurrentMediaTime() - startTime)
                    }, onError: { [weak self] (error) in
                        guard let self = self else { return }
                        forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
                        tracker.error(error)
                        ShareChatAlertProvider.logger.error("share group card failed",
                                                            additionalData: ["chatId": chatId],
                                                            error: error)
                    })
    }
}
