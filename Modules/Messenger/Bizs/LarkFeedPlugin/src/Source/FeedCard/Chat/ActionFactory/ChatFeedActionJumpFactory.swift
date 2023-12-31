//
//  ChatFeedActionJumpFactory.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/7/17.
//

import LarkModel
import LarkOpenFeed
import LarkSDKInterface
import LarkAccountInterface
import LarkMessengerInterface
import RxSwift
import RustPB
import LarkCore
import LarkUIKit
import UniverseDesignDialog

final class ChatFeedActionJumpFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .jump
    }

    var bizType: FeedPreviewType? {
        return .chat
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return ChatFeedActionJumpHandler(type: type, model: model, context: context)
    }
}

final class ChatFeedActionJumpHandler: FeedActionHandler {
    private let disposeBag = DisposeBag()
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        guard let vc = model.fromVC ?? context.feedContextService.page else { return }
        self.willHandle()
        self.tryRouterToChat(feedPreview: model.feedPreview, from: vc)
        self.didHandle()
    }

    /// 跳转Chat会话
    private func tryRouterToChat(feedPreview: FeedPreview, from: UIViewController) {
        guard let chatAPI = try? context.userResolver.resolve(assert: ChatAPI.self) else { return }
        // 如果被踢出群聊，需弹框拦截，同时移除该Feed
        guard feedPreview.preview.chatData.chatRole == .member else {
            chatAPI.getKickInfo(chatId: feedPreview.id)
                .timeout(.milliseconds(500), scheduler: MainScheduler.instance)
                .asDriver(onErrorJustReturn: BundleI18n.LarkFeedPlugin.Lark_IM_YouAreNotInThisChat_Text)
                .drive(onNext: { [weak self] (content) in
                    let dialog = UDDialog()
                    dialog.setContent(text: content, numberOfLines: 0)
                    dialog.addPrimaryButton(text: BundleI18n.LarkFeedPlugin.Lark_Legacy_IKnow, dismissCompletion: { [weak self] in
                        guard let self = self else { return }
                        self.removeFeed(feedPreview: feedPreview)
                    })
                    self?.context.userResolver.navigator.present(dialog, from: from)
                }).disposed(by: self.disposeBag)
            return
        }
        if feedPreview.preview.chatData.isCrypto,
           let passportUserService = try? context.userResolver.resolve(assert: PassportUserService.self),
           !passportUserService.userTenant.isByteDancer {
            SecretChatFirstCheck.showSecretChatNoticeIfNeeded(
                navigator: context.userResolver.navigator,
                targetVC: from,
                cancelAction: nil
            ) { [weak self] in
                self?.pushChatController(feedPreview: feedPreview, from: from)
            }
        } else {
            pushChatController(feedPreview: feedPreview, from: from)
        }
        FeedCellTrack.trackViewChatInChatbox(feedPreview)
    }

    private func pushChatController(feedPreview: FeedPreview, from: UIViewController) {
        let body = ChatControllerByBasicInfoBody(
            chatId: feedPreview.id,
            fromWhere: .feed,
            isCrypto: feedPreview.preview.chatData.isCrypto,
            isMyAI: feedPreview.preview.chatData.isP2PAi,
            chatMode: feedPreview.preview.chatData.chatMode,
            extraInfo: ["feedId": feedPreview.id])
        let contextData: [String: Any] = [FeedSelection.contextKey: FeedSelection(feedId: feedPreview.id)]
        context.userResolver.navigator.showDetailOrPush(
            body: body,
            context: contextData,
            wrap: LkNavigationController.self,
            from: from)
    }

    // 如果被踢出群聊，需弹框拦截，同时移除该Feed
    private func removeFeed(feedPreview: FeedPreview) {
        var channel = Basic_V1_Channel()
        channel.type = .chat
        channel.id = feedPreview.id
        let feedAPI = try? context.userResolver.resolve(assert: FeedAPI.self)
        feedAPI?.removeFeedCard(channel: channel, feedType: .chat)
            .subscribe()
            .disposed(by: disposeBag)
    }
}
