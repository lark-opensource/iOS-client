//
//  FeedActionBlockMsgFactory.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/7/12.
//

import LarkOpenFeed
import LarkSDKInterface
import RustPB
import RxSwift
import LarkModel

final class ChatFeedActionBlockMsgFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .blockMsg
    }

    var bizType: FeedPreviewType? {
        return .chat
    }

    func createActionViewModel(model: FeedActionModel, context: FeedCardContext) -> FeedActionViewModelInterface? {
        return ChatFeedActionBlockMsgViewModel(model: model)
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return ChatFeedActionBlockMsgHandler(type: type, model: model, context: context)
    }
}

final class ChatFeedActionBlockMsgViewModel: FeedActionViewModelInterface {
    private let disposeBag = DisposeBag()
    let title: String
    let contextMenuImage: UIImage
    init(model: FeedActionModel) {
        self.title = model.feedPreview.preview.chatData.mutedBotP2P ? BundleI18n.LarkFeedPlugin.Lark_BotMsg_RestoreReceivingOption :
                                                         BundleI18n.LarkFeedPlugin.Lark_BotMsg_StopReceivingOption
        self.contextMenuImage = model.feedPreview.preview.chatData.mutedBotP2P ? Resources.LarkFeedPlugin.chatOutlined :
                                                         Resources.LarkFeedPlugin.chatForbiddenOutlined
    }
}

final class ChatFeedActionBlockMsgHandler: FeedActionHandler {
    private let disposeBag = DisposeBag()
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        self.willHandle()
        var botMutedInfo = Basic_V1_Chatter.BotMutedInfo()
        botMutedInfo.mutedScenes = ["p2p_chat": !model.feedPreview.preview.chatData.mutedBotP2P]
        let chatterAPI = try? context.userResolver.resolve(assert: ChatterAPI.self)
        chatterAPI?.updateBotForbiddenState(chatterId: model.feedPreview.preview.chatData.chatterID, botMuteInfo: botMutedInfo)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.didHandle()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.didHandle(error: error)
            }).disposed(by: self.disposeBag)
    }
}
