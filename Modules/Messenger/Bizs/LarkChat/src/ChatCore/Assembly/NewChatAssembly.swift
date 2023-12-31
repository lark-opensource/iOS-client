//
//  ChatAssembly.swift
//  LarkChat
//
//  Created by liuwanlin on 2018/8/3.
//

import ByteWebImage
import Foundation
import LarkContainer
import LarkModel
import LarkUIKit
import LarkRustClient
import LarkCore
import Swinject
import EENavigator
import LarkMessageCore
import LarkMessageBase
import LKCommonsLogging
import LarkMessengerInterface
import LarkFeatureSwitch
import RxSwift
import LarkSDKInterface
import LarkFeatureGating
import LarkAssembler
import LarkOpenFeed

public final class NewChatAssembly: LarkAssemblyInterface {
    private static let logger: Log = Logger.log(NewChatAssembly.self, category: "NewChatAssembly")

    public let config: NewChatAssemblyConfig

    public init(config: NewChatAssemblyConfig) {
        self.config = config
    }
    public func registContainer(container: Container) {
        let user = container.inObjectScope(M.userScope)
        // let userGraph = container.inObjectScope(M.userGraph)
        // 翻译服务
        user.register(NormalTranslateService.self) { r in
            return try NormalTranslateServiceImpl(userResolver: r, dependency: TranslateServiceDependencyImpl(resolver: r))
        }
    }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(ChatControllerByChatBody.self)
        .factory(ChatControllerByChatHandler.init)

        Navigator.shared.registerRoute.type(MessagePickerBody.self).factory(MessagePickerHandler.init)

        // 进入代码详情页面
        Navigator.shared.registerRoute.type(CodeDetailBody.self)
        .factory(CodeDetailHandler.init)

        Navigator.shared.registerRoute.type(InnerChatControllerBody.self).factory(cache: true, InnerChatControllerHandler.init)

        let wrapperCanGoToChatByExternalURL: () -> Router = {
            // 聊天页面
            if self.config.canGoToChatByExternalURL {
                Self.logger.info("NewChatAssembly URLInterceptorManager begin register ChatControllerByIdBody")
                URLInterceptorManager.shared.register(ChatControllerByIdBody.patternConfig.pattern) { (url, from) in
                    Navigator.shared.showDetailOrPush(url: url, tab: .feed, from: from)
                }
            }
            return Router()
        }
        wrapperCanGoToChatByExternalURL()
    }

    public func registURLInterceptor(container: Container) {
        // 值班号
        (OncallChatBody.pattern, {(url, from) in
            Navigator.shared.showDetailOrPush(url: url, tab: .feed, from: from)
        })
    }

    @_silgen_name("Lark.ChatCellFactory.Messenger.ChatVC")
    static public func chatCellFactoryRegister() {
        MessageEngineSubFactoryRegistery.register(LocationContentFactory.self)
        MessageEngineSubFactoryRegistery.register(FolderContentFactory.self)
        MessageEngineSubFactoryRegistery.register(FileContentFactory.self)
        MessageEngineSubFactoryRegistery.register(NewVoteContentFactory.self)
        MessageEngineSubFactoryRegistery.register(FoldMessageContentFactory.self)
        MessageEngineSubFactoryRegistery.register(MessageLinkAudioContentFactory.self)
        MessageEngineSubFactoryRegistery.register(MessageLinkRecalledContentFactory.self)
        MessageEngineSubFactoryRegistery.register(ShareGroupContentFactory.self)
        MessageEngineSubFactoryRegistery.register(MessageLinkImageContentFactory.self)
        MessageEngineSubFactoryRegistery.register(BaseStickerContentFactory.self)
        MessageEngineSubFactoryRegistery.register(ForwardThreadMergeForwardContentFactory.self)
        MessageEngineSubFactoryRegistery.register(RedPacketContentFactory.self)
        MessageEngineSubFactoryRegistery.register(BaseShareUserCardContentFactory.self)
        MessageEngineSubFactoryRegistery.register(ForwardThreadTextPostContentFactory.self)
        MessageEngineSubFactoryRegistery.register(BaseVideoContentFactory.self)
        MessageEngineSubFactoryRegistery.register(BaseVoteContentFactory.self)

        ChatPinMessageEngineSubFactoryRegistery.register(LocationContentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(ChatPinFolderContentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(ChatPinFileContentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(ChatPinVoteContentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(FoldMessageContentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(ChatPinAudioContentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(MessageLinkRecalledContentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(ChatPinShareGroupContentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(MessageLinkImageContentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(BaseStickerContentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(ChatPinMergeForwardContentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(RedPacketContentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(ChatPinShareUserCardContentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(ChatPinTextPostContentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(BaseVideoContentFactory.self)
        ChatPinMessageEngineSubFactoryRegistery.register(BaseVoteContentFactory.self)

        MessageLinkSubFactoryRegistery.register(MessageLinkFolderContentFactory.self)
        MessageLinkSubFactoryRegistery.register(MessageLinkFileContentFactory.self)
        MessageLinkSubFactoryRegistery.register(MessageLinkAudioContentFactory.self)
        MessageLinkSubFactoryRegistery.register(MessageLinkImageContentFactory.self)
        MessageLinkSubFactoryRegistery.register(MessageLinkStickerContentFactory.self)
        MessageLinkSubFactoryRegistery.register(MessageLinkMergeForwardContentFactory.self)
        MessageLinkSubFactoryRegistery.register(MessageLinkTextPostContentFactory.self)
        MessageLinkSubFactoryRegistery.register(MessageLinkVideoContentFactory.self)
        MessageLinkSubFactoryRegistery.register(RevealReplyInTreadComponentFactory.self)
        MessageLinkSubFactoryRegistery.register(MessageLinkReactionComponentFactory.self)
        MessageLinkSubFactoryRegistery.register(MessageLinkReplyComponentFactory.self)

        MessageLinkDetailSubFactoryRegistery.register(MessageLinkFolderContentFactory.self)
        MessageLinkDetailSubFactoryRegistery.register(MessageLinkFileContentFactory.self)
        MessageLinkDetailSubFactoryRegistery.register(MessageLinkDetailAudioContentFactory.self)
        MessageLinkDetailSubFactoryRegistery.register(MergeForwardImageContentFactory.self)
        MessageLinkDetailSubFactoryRegistery.register(MessageLinkStickerContentFactory.self)
        MessageLinkDetailSubFactoryRegistery.register(MessageLinkMergeForwardContentFactory.self)
        MessageLinkDetailSubFactoryRegistery.register(MessageLinkTextPostContentFactory.self)
        MessageLinkDetailSubFactoryRegistery.register(MessageLinkDetailVideoContentFactory.self)
        MessageLinkDetailSubFactoryRegistery.register(RevealReplyInTreadComponentFactory.self)
        MessageLinkDetailSubFactoryRegistery.register(ReactionComponentFactory.self)
        MessageLinkDetailSubFactoryRegistery.register(ReplyComponentFactory.self)

        // NewChat
        ChatMessageSubFactoryRegistery.register(ChatRecalledContentFactory.self)
        ChatMessageSubFactoryRegistery.register(MultiEditComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(ChatTextPostContentFactory.self)
        ChatMessageSubFactoryRegistery.register(ImageContentFactory.self)
        ChatMessageSubFactoryRegistery.register(BaseStickerContentFactory.self)
        ChatMessageSubFactoryRegistery.register(BaseVideoContentFactory.self)
        ChatMessageSubFactoryRegistery.register(BaseAudioContentFactory.self)
        // 密聊不支持translate，不注册
        ChatMessageSubFactoryRegistery.register(TranslatedByReceiverCompententFactory.self)
        // 密聊不支持translate，不注册
        ChatMessageSubFactoryRegistery.register(TranslateStatusComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(FileContentFactory.self)
        ChatMessageSubFactoryRegistery.register(FolderContentFactory.self)
        ChatMessageSubFactoryRegistery.register(LocationContentFactory.self)
        ChatMessageSubFactoryRegistery.register(ShareGroupContentFactory.self)
        ChatMessageSubFactoryRegistery.register(BaseVoteContentFactory.self)
        ChatMessageSubFactoryRegistery.register(NewVoteContentFactory.self)
        ChatMessageSubFactoryRegistery.register(BaseShareUserCardContentFactory.self)
        ChatMessageSubFactoryRegistery.register(RedPacketContentFactory.self)

        ChatMessageSubFactoryRegistery.register(ChatReactionComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(NewChatMessageStatusComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(FlagComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(ChatterStatusLabelFactory.self)
        ChatMessageSubFactoryRegistery.register(ReplyComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(SyncToChatComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(ReplyStatusComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(ReplyThreadInfoComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(UrgentTipsComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(UrgentComponentFactory.self)
        // 暂时去掉转发提示
//        ChatMessageSubFactoryRegistery.register(ForwardComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(ChatMergeForwardContentFactory.self)
        ChatMessageSubFactoryRegistery.register(DocPreviewComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(URLPreviewComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(TCPreviewContainerComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(PinComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(ChatPinComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(DlpTipComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(FileNotSafeComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(RestrictComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(FoldMessageContentFactory.self)
        ChatMessageSubFactoryRegistery.register(RevealReplyInTreadComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(CountDownStatusComponentFactory.self)

        // MergeForward
        MergeForwardMessageSubFactoryRegistery.register(RecalledContentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(MergeForwardTextPostContentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(MergeForwardImageContentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(MergeForwardStickerContentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(MergeForwardVideoContentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(MergeForwardAudioContentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(MergeForwardFileContentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(MergeForwardFolderContentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(LocationContentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(ShareGroupContentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(BaseVoteContentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(MergeForwardNewVoteContentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(BaseShareUserCardContentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(RedPacketContentFactory.self)

        MergeForwardMessageSubFactoryRegistery.register(ReactionComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(MessageStatusComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(ChatterStatusLabelFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(ReplyComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(SyncToChatComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(ReplyStatusComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(ReplyThreadInfoComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(RevealReplyInTreadComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(UrgentComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(UrgentTipsComponentFactory.self)
        // 暂时去掉转发提示
//        MergeForwardMessageSubFactoryRegistery.register(ForwardComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(ChatMergeForwardContentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(DocPreviewComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(URLPreviewComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(PinComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(DlpTipComponentFactory.self)
        MergeForwardMessageSubFactoryRegistery.register(FileNotSafeComponentFactory.self)

        // 密聊
        CryptoChatMessageSubFactoryRegistery.register(ChatRecalledContentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(DecryptedFailedContentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(CryptoTextContentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(CryptoChatImageContentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(BaseStickerContentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(CryptoChatAudioContentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(CryptoChatFileContentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(LocationContentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(BaseShareUserCardContentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(CryptoReactionComponentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(NewChatMessageStatusComponentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(ChatterStatusLabelFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(ReplyComponentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(CryptoTextReplyComponentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(ReplyStatusComponentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(CryptoUrgentTipsComponentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(UrgentComponentFactory.self)
        CryptoChatMessageSubFactoryRegistery.register(CryptoCountDownStatusComponentFactory.self)

//        NormalChatCellLifeCycleObseverRegister.register(obseverGenerator: {
//            return CellLifeCycleObseverDemo()
//        })
        NormalChatCellLifeCycleObseverRegister.register(obseverGenerator: ChatTabGuideCellLifeCycleObserver.init)
        NormalChatCellLifeCycleObseverRegister.register(obseverGenerator: ChatDocsCellLifeCycleObserver.init)
        NormalChatCellLifeCycleObseverRegister.register(obseverGenerator: {
            return ChatImageCellLifeCycleObserver()
        })
        NormalChatCellLifeCycleObseverRegister.register(obseverGenerator: ChatWAContainerLiftCycleObserver.init)
    }

    @_silgen_name("Lark.Feed.FloatMenu.IM")
    static public func feedFloatMenuRegister() {
        FeedFloatMenuModule.register(ChatNewGroupMenuSubModule.self)
    }
}

final class NewChatMessageStatusComponentFactory: MessageStatusComponentFactory<ChatContext> {
    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, ChatContext> {
        return NewChatMessageStatusViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context)
    }
}

final class NewChatMessageStatusViewModel<M: CellMetaModel, D: CellMetaModelDependency>: MessageStatusViewModel<M, D, ChatContext> {
    init(metaModel: M, metaModelDependency: D, context: ChatContext) {
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: MessageStatusComponentBinder<M, D, ChatContext>(context: context))
    }

    override func showReadStatusDetail() {
        super.showReadStatusDetail()
        ChatTracker.trackEnterReadStatus()
    }
}
