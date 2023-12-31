//
//  FlagCellViewModelFactory.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import LarkModel
import RustPB
import LarkFeatureGating
import LarkOpenFeed
import LarkContainer
import Swinject
import LarkMessageBase
import LarkSetting

public final class FlagCellViewModelFactory: UserResolverWrapper {
    public let userResolver: UserResolver
    @ScopedInjectedLazy var feedCardModuleManager: FeedCardModuleManager?
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    // MessageVM工厂
    func createMessageVM(flag: RustPB.Feed_V1_FlagItem,
                         messageId: String, messages: [String: Message],
                         chats: [String: Chat],
                         dataDependency: FlagDataDependency,
                         componentFactory: FlagListMessageViewModelFactory? = nil) -> FlagMessageCellViewModel? {
        guard let message = messages[messageId] else { return nil }
        let chat = chats[message.channel.id]
        let content = MessageFlagContent(chat: chat, message: message)
        if message.isRecalled || message.isDeleted || message.isCleaned {
            return FlagRecallMessageViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency)
        }
        switch message.type {
        case .text:
            return FlagPostMessageViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency)
        case .post:
            return FlagPostMessageViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency)
        case .image:
            return FlagImageMessageViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency)
        case .media:
            return FlagVideoMessageViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency)
        case .sticker:
            return FlagStickerMessageViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency)
        case .file:
            return FlagFileMessageViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency)
        case .folder:
            return FlagFolderMessageViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency)
        case .audio:
            let audioVM = FlagAudioMessageViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency)
            return audioVM
        case .location:
            return FlagLocationMessageViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency)
        case .mergeForward:
            if let mergeForwardContent = message.content as? MergeForwardContent,
                mergeForwardContent.isFromPrivateTopic {
                if let chat = chat, let factory = componentFactory {
                    let metaModel = FlagListMessageMetaModel(message: message, chat: chat)
                    if let dependency = factory.getCellDependency?(),
                       let vm = factory.create(with: metaModel, metaModelDependency: dependency) as? FlagListMessageComponentViewModel {
                        return FlagMessageComponentCellViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency, componentViewModel: vm)
                    }
                }
                return FlagMergeForwardPostCardMessageViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency)
            } else {
                return FlagMergeForwardMessageViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency)
            }
        case .vote, .shareGroupChat, .shareUserCard, .card, .shareCalendarEvent, .generalCalendar, .todo:
            if let chat = chat, let factory = componentFactory {
                let metaModel = FlagListMessageMetaModel(message: message, chat: chat)
                if let dependency = factory.getCellDependency?(),
                   let vm = factory.create(with: metaModel, metaModelDependency: dependency) as? FlagListMessageComponentViewModel {
                    return FlagMessageComponentCellViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency, componentViewModel: vm)
                }
            }
            return FlagUnknownMessageViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency)
        case .unknown, .system, .email, .calendar, .hongbao, .commercializedHongbao, .videoChat, .diagnose:
            return FlagUnknownMessageViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency)
        @unknown default:
            return FlagUnknownMessageViewModel(userResolver: userResolver, flag: flag, content: content, dataDependency: dataDependency)
        }
    }

    // FeedVM工厂
    public func createFeedVM(feed: FeedPreview, dataDependency: FlagDataDependency) -> FeedCardViewModelInterface? {
        guard let feedCardModuleManager = feedCardModuleManager else { return nil }
        return FeedCardContext.cellViewModelBuilder?(feed, userResolver, feedCardModuleManager, .flag, .flag, [:])
    }
}
