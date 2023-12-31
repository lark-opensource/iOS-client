//
//  FlagListViewModel+DataHandler.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/19.
//

import Foundation
import RxSwift
import RxDataSources
import LarkSDKInterface
import RustPB
import UniverseDesignToast
import LKCommonsLogging
import LarkModel
import TangramService
import LarkAccountInterface

// MARK: - DataHandler
extension FlagListViewModel {
    // 处理收到的PushFlag消息
    func handleMessageFromPushFlag(pushFlagMessage: PushFlagMessage) {
        let updateFlags = pushFlagMessage.updateFlags
        let removeFlags = pushFlagMessage.deleteFlags
        let source = pushFlagMessage.source
        let chats = source.chats
        let chatters = source.chatters
        // updateFlags支持传[]触发reload，所以此处需要判空，否则会触发一次无用table更新
        if !updateFlags.isEmpty {
            let updateIds = self.getFlagIdsBy(flags: updateFlags)
            FlagListViewModel.logger.info("LarkFlag: [PushFlag][UpdateFlags] updateIds = \(updateIds)")
            let feedCards = pushFlagMessage.flagFeeds.feedCards.map { feedEntityPreview in
                feedEntityPreview.feedID
            }
            FlagListViewModel.logger.info("LarkFlag: [PushFlag][UpdateFlags] feedCards = \(feedCards)")
            var messages: [String] = []
            for (key, _) in pushFlagMessage.flagMessages.entity.messages {
                messages.append(key)
            }
            FlagListViewModel.logger.info("LarkFlag: [PushFlag][UpdateFlags] messages = \(messages)")
            self.updateFlags(flags: updateFlags, flagFeeds: pushFlagMessage.flagFeeds, flagMessages: pushFlagMessage.flagMessages)
        }
        // 需要删除的flag为空则无需调用
        if !removeFlags.isEmpty {
            let removeIds = self.getFlagIdsBy(flags: removeFlags)
            FlagListViewModel.logger.info("LarkFlag: [PushFlag][RemoveFlags] removeIds = \(removeIds)")
            self.removeFlags(flags: removeFlags, flagFeeds: pushFlagMessage.flagFeeds, flagMessages: pushFlagMessage.flagMessages)
        }
        // 更新消息类型标记的chats
        if !chats.isEmpty {
            let chatIds = self.getChatIdsBy(chats: chats)
            FlagListViewModel.logger.info("LarkFlag: [PushFlag][Chats] chatIds = \(chatIds)")
            self.updateChats(chats: chats)
        }
        // 更新消息类型标记的chatters
        if !chatters.isEmpty {
            let chatterIds = self.getChatterIdsBy(chatters: chatters)
            FlagListViewModel.logger.info("LarkFlag: [PushFlag][Chatters] chatterIds = \(chatterIds)")
            self.updateChatters(chatters: chatters)
        }
    }

    // 处理收到的is24HourTime消息: 直接触发一次table的reload
    func handleIs24HourTime() {
        self.updateFlags(flags: [], flagFeeds: Feed_V1_FeedFlags(), flagMessages: Feed_V1_MessageFlags())
    }

    // 处理收到的标记总数
    func handleUnReadCount(_ filtersInfo: [Feed_V1_FeedFilter.TypeEnum: FlagPushFeedFilterInfo]) {
        filtersInfo.forEach { (type: Feed_V1_FeedFilter.TypeEnum, filter: FlagPushFeedFilterInfo) in
            guard type == .flag else { return }
            self.totalCount = filter.unread
        }
    }

    // 处理收到的pushFeedMessage消息：只处理update的feed，不用处理remove的
    func handleFeedFromPushFeed(pushFeedMessage: PushFeedMessage) {
        let updateFeeds = pushFeedMessage.updateFeeds.filter { (_, value) in
            return value.feedPreview.basicMeta.isFlaged == true
        }
        // 把需要更新的feeds转成FlagItems
        var updatedFlags = [FlagItem]()
        updateFeeds.forEach { [weak self] (key: String, value: PushUpdateFeedInfo) in
            guard let `self` = self else { return }
            guard let feedVM = self.cellViewModelFactory.createFeedVM(feed: value.feedPreview, dataDependency: dataDependency) else { return }
            var createTime: Double = Double(value.feedPreview.basicMeta.rankTime)
            let rankTime: Double = Double(value.feedPreview.basicMeta.rankTime)
            let updateTime: Double = Double(value.feedPreview.basicMeta.updateTime)
            let uniqueId = "feed_" + key
            if let findItem = self.provider.getItemBy(uniqueId: uniqueId) {
                createTime = findItem.createTime
            }
            let item = FlagItem(type: .feed, flagId: key, createTime: createTime, rankTime: rankTime, updateTime: updateTime, cellViewModel: feedVM)
            // 暂存更新的flagItem, 以供批量更新Provider数据源
            updatedFlags.append(item)
        }
        // 需要更新的flagItem为空则无需调用
        if !updatedFlags.isEmpty {
            // 更新数据源项
            self.updateFlags(flags: updatedFlags)
            let updateIds = updatedFlags.map { flagItem in
                return "feed_" + flagItem.flagId
            }
            FlagListViewModel.logger.info("LarkFlag: [PushFeedPreview] updateIds = \(updateIds)")
        }
    }

    // 处理收到的pushFeedFilterMessage消息：标记的排序会发生改变
    func handleFeedFilterMessage(pushFeedFilterMessage: PushFeedFilterMessage) {
        FlagListViewModel.logger.info("LarkFlag: [PushFeedFilter] pushFeedFilterMessage.flagSortingRule = \(pushFeedFilterMessage.flagSortingRule), self.sortingRule = \(self.sortingRule)")
        guard pushFeedFilterMessage.flagSortingRule != .unknownRule else {
            return
        }
        guard pushFeedFilterMessage.flagSortingRule != self.sortingRule else {
            return
        }
        FlagListViewModel.logger.info("LarkFlag: [PushFeedFilter] sortingRule changed! = \(pushFeedFilterMessage.flagSortingRule)")
        // 标记的排序方式发生变化，需要清空原来的数据，再从第一页开始拉取新数据
        self.sortingRule = pushFeedFilterMessage.flagSortingRule
        // 重置分页游标
        self.resetCursor()
        // 清空数据
        self.provider.removeAllItems()
        // 更新排序规则
        self.provider.setFlagSortingRole(self.sortingRule)
        // 重新拉取新的数据
        self.loadMore()
    }

    // 处理收到的PushInlinePreview消息
    func handleMessageFromInlinePreviewPush(urlPreview: URLPreviewPush) {
        let pair = urlPreview.inlinePreviewEntityPair
        let value = self.datasource.value
        value.forEach { flagItem in
            if let message = flagItem.messageVM?.message,
               let body = self.dataDependency.inlinePreviewVM.getInlinePreviewBody(message: message, pair: pair),
               self.dataDependency.inlinePreviewVM.update(message: message, body: body) {
                // 触发message刷新
                flagItem.messageVM?.message = message
            }
        }
        self.datasource.accept(self.datasource.value)
    }

    // 更新flagItem里面的chat
    func updateChats(chats: [Basic_V1_Chat]) {
        let value = self.datasource.value
        let chatId2Chat = Dictionary(uniqueKeysWithValues: chats.map { ($0.id, $0) })
        value.forEach { flagItem in
            if let messageVM = flagItem.messageVM, let pbChat = chatId2Chat[messageVM.message.chatID] {
                let chat = Chat.transform(pb: pbChat)
                messageVM.updateChat(chat)
            }
        }
        self.fireFlagsRefresh(refreshType: .reload)
    }

    // 更新flagItem里面的chatter
    func updateChatters(chatters: [Basic_V1_Chatter]) {
        let value = self.datasource.value
        let chatterId2Chatter = Dictionary(uniqueKeysWithValues: chatters.map { ($0.id, $0) })
        value.forEach { flagItem in
            if let messageVM = flagItem.messageVM, let chatterId = messageVM.message.fromChatter?.id, let chatter = chatterId2Chatter[chatterId] {
                let chatter = Chatter.transform(pb: chatter)
                messageVM.updateFromChatter(chatter)
            }
        }
        self.fireFlagsRefresh(refreshType: .reload)
    }

    // 更新Feed：feeds为[FlagItem]
    func updateFlags(flags: [FlagItem]) {
        // 如果flags为[]，直接触发一次reload
        guard !flags.isEmpty else {
            self.fireFlagsRefresh(changedUniqueIds: [], refreshType: .reload)
            return
        }
        // 更新数据源项
        self.provider.updateItems(flags)
        self.fireFlagsRefresh(changedUniqueIds: flags.map({ $0.uniqueId }), refreshType: .reload)
    }

    // 更新Feed：feeds为[]，将直接触发一次reload
    func updateFlags(flags: [Feed_V1_FlagItem], flagFeeds: Feed_V1_FeedFlags, flagMessages: Feed_V1_MessageFlags) {
        // 如果flags为[]，直接触发一次reload
        guard !flags.isEmpty else {
            FlagListViewModel.logger.error("LarkFlag: [UpdateFlags] flags.isEmpty == true")
            self.fireFlagsRefresh(changedUniqueIds: [], refreshType: .reload)
            return
        }
        // 更新总数据源
        var updatedFlagItems = [FlagItem]()
        // 提前为vm数组预留空间, 避免多次空间分配，提高性能
        updatedFlagItems.reserveCapacity(flags.count)
        var oldFlags: [String] = []
        flags.forEach { flag in
            guard let flagItem = self.createFlagItem(flag: flag, flagFeeds: flagFeeds, flagMessages: flagMessages) else {
                FlagListViewModel.logger.error("LarkFlag: [UpdateFlags] createFlagItem == nil")
                return
            }
            if let oldFlag = self.provider.getItemBy(uniqueId: flagItem.uniqueId), Double(flag.updateTime) < oldFlag.updateTime {
                FlagListViewModel.logger.error("LarkFlag: [UpdateFlags] flag.updateTime < oldFlag.updateTime")
                // 如果新到来的flag比端上cache里对应的老flag的updateTime小，则丢弃
                oldFlags.append(flagItem.uniqueId)
                return
            }
            if let removeTime = self.removedFlags[flagItem.flagId], Double(flag.updateTime) < removeTime {
                FlagListViewModel.logger.error("LarkFlag: [UpdateFlags] flag.updateTime < removeTime")
                // 如果新到来的flag比端上cache里对应的老flag的updateTime小，则丢弃
                oldFlags.append(flagItem.uniqueId)
                return
            }
            // 暂存更新的flagItem, 以供批量更新Provider数据源
            updatedFlagItems.append(flagItem)
        }
        FlagListViewModel.logger.info("LarkFlag: [UpdateFlags] oldFlags = \(oldFlags)")
        let updateIds = updatedFlagItems.map { flagItem in
            flagItem.uniqueId
        }
        FlagListViewModel.logger.info("LarkFlag: [UpdateFlags] updatedFlagItems = \(updateIds)")
        // 更新数据源项
        self.provider.updateItems(updatedFlagItems)
        self.fireFlagsRefresh(changedUniqueIds: updatedFlagItems.map({ $0.uniqueId }), refreshType: .reload)
    }

    // 删除Feed：feeds为[]时，忽略；若要直接触发reload，使用updateFeeds
    func removeFlags(flags: [Feed_V1_FlagItem], flagFeeds: Feed_V1_FeedFlags, flagMessages: Feed_V1_MessageFlags) {
        var uniqueIds: [String] = []
        var removeUniqueIds: [String] = []
        var oldUniqueIds: [String] = []

        flags.forEach { flag in
            let (flagId, flagType) = self.getFlagItemIdAndType(flag: flag)
            guard let flagId = flagId, let flagType = flagType else {
                return
            }
            var uniqueId = "feed_" + flagId
            if flagType == .message {
                uniqueId = "message_" + flagId
            }
            uniqueIds.append(uniqueId)
            if flag.updateTime == -2 {
                // 旧逻辑直接删除
                // 暂存删除的ids, 以供批量删除Provider数据源
                removeUniqueIds.append(uniqueId)
            } else {
                // 新逻辑先判断再删除
                if let oldFlag = self.provider.getItemBy(uniqueId: uniqueId), Double(flag.updateTime) < oldFlag.updateTime {
                    FlagListViewModel.logger.error("LarkFlag: [RemoveFlags] flag.updateTime < oldFlag.updateTime")
                    // 如果新到来的flag比端上cache里对应的老flag的updateTime小，则丢弃
                    oldUniqueIds.append(uniqueId)
                    return
                }

                if let removeTime = self.removedFlags[uniqueId], Double(flag.updateTime) < removeTime {
                    FlagListViewModel.logger.error("LarkFlag: [RemoveFlags] flag.updateTime < removeTime")
                    // 如果新到来的feed比端上cache里对应的老feed的updateTime小，则丢弃
                    oldUniqueIds.append(uniqueId)
                    return
                }

                // 暂存删除的ids, 以供批量删除Provider数据源
                removeUniqueIds.append(uniqueId)
                // 更新缓存的数据
                self.removedFlags[uniqueId] = Double(flag.updateTime)
            }
        }
        FlagListViewModel.logger.info("LarkFlag: [RemoveFlags] oldFlags = \(oldUniqueIds)")
        FlagListViewModel.logger.info("LarkFlag: [RemoveFlags] removeFlagItems = \(removeUniqueIds)")
        self.provider.removeItems(removeUniqueIds)
        // 删除一条数据后，如果当前数据源的条数小于服务端总的标记条数 并且 页面上展示的数据已经小于一个分页的数量
        // 那么需要加载更多的数据，否则会出现删着删着显示的条数变少和标题上实际显示的数量不匹配的问题
        let dataCount = self.provider.getItemsArray().count
        if dataCount < self.totalCount && dataCount < self.countPerPage {
            self.loadMore()
        }
        // 不管怎样只要数据源发生变化了，一定要刷新界面
        self.fireFlagsRefresh(changedUniqueIds: removeUniqueIds, refreshType: .delete)
    }

    // 外部不要直接使用，要触发Feed更新，都应该通过updateFlags和removeFlags
    func fireFlagsRefresh(changedUniqueIds: [String] = [], refreshType: RefreshType) {
        self.refreshType = refreshType
        FlagListViewModel.logger.info("LarkFlag: [FireFlagsRefresh] changedIds = \(changedUniqueIds), refreshType = \(refreshType)")
        let items = provider.getItemsArray()
        self.datasource.accept(items)
    }

    // 获取FlagItem的id：feedId或者messageId
    func getFlagItemIdAndType(flag: Feed_V1_FlagItem) -> (String?, FlagItemType?) {
        switch flag.key.key {
        case .feedPair(let feedPair):
            return (String(feedPair.feedCardID), .feed)
        case .messageID(let messageId):
            return (String(messageId.messageID), .message)
        @unknown default:
            return (nil, nil)
        }
    }

    // 根据FlagItem和相关信息创建FlagItem
    func createFlagItem(flag: Feed_V1_FlagItem, flagFeeds: RustPB.Feed_V1_FeedFlags, flagMessages: RustPB.Feed_V1_MessageFlags) -> FlagItem? {
        switch flag.key.key {
        case .feedPair(let feedPair):
            let feeds = flagFeeds.feedCards.filter { feedEntityPreview in
                return feedEntityPreview.feedID == (String(feedPair.feedCardID))
            }
            if let feed = feeds.first {
                let feedPreview = FeedPreview.transformByEntityPreview(feed)
                if let feedVM = self.cellViewModelFactory.createFeedVM(feed: feedPreview, dataDependency: dataDependency) {
                    let createTime = flag.cursor.rankTime
                    let rankTime = feedPreview.basicMeta.rankTime
                    FlagListViewModel.logger.info("LarkFlag: [CreateFlagItem] type = .feed, flagId = \(feedPreview.id), createTime = \(createTime), rankTime = \(rankTime)")
                    return FlagItem(type: .feed, flagId: feedPreview.id, createTime: Double(createTime), rankTime: Double(rankTime), updateTime: Double(flag.updateTime), cellViewModel: feedVM)
                }
            }
        case .messageID(let messageId):
            var messages: [String: Message] = [:]
            for (key, value) in flagMessages.entity.messages {
                let message = Message.transform(pb: value)
                if message.type == .text, var textContent = message.content as? TextContent {
                    // 初始化inlinePreviewEntities
                    textContent.complement(entity: flagMessages.entity, message: message)
                    message.content = textContent
                } else if message.type == .mergeForward, let mergeForwardContent = message.content as? MergeForwardContent {
                    mergeForwardContent.complement(entity: flagMessages.entity, message: message)
                    message.content = mergeForwardContent
                } else if message.type == .shareGroupChat, var shareGroupChatContent = message.content as? ShareGroupChatContent {
                    shareGroupChatContent.complement(entity: flagMessages.entity, message: message)
                    message.content = shareGroupChatContent
                } else if message.type == .shareUserCard, var shareUserCardContent = message.content as? ShareUserCardContent {
                    shareUserCardContent.complement(entity: flagMessages.entity, message: message)
                    message.content = shareUserCardContent
                }
                message.fromChatter = try? Chatter.transformChatter(entity: flagMessages.entity, message: value, id: value.fromID)
                messages[key] = message
            }
            var chats: [String: Chat] = [:]
            for (key, value) in flagMessages.entity.chats {
                chats[key] = Chat.transform(pb: value)
            }
            // 如果消息类型标记的entity实体是空的打一个错误日志
            if messages.isEmpty {
                FlagListViewModel.logger.error("LarkFlag: [CreateFlagItem] type = .message, id = \(messageId.messageID),  flagMessages.entity.messages is empty")
            }
            if let messageVM = self.cellViewModelFactory.createMessageVM(flag: flag, messageId: String(messageId.messageID),
                                                                         messages: messages, chats: chats, dataDependency: dataDependency, componentFactory: flagComponentVMFactory) {
                let msgId = String(messageId.messageID)
                let createTime = flag.cursor.rankTime
                let rankTime = messageVM.message.createTime
                FlagListViewModel.logger.info("LarkFlag: [CreateFlagItem] type = .message, flagId = \(msgId), createTime = \(createTime), rankTime = \(rankTime)")
                return FlagItem(type: .message, flagId: msgId, createTime: Double(createTime), rankTime: Double(rankTime), updateTime: Double(flag.updateTime), cellViewModel: messageVM)
            }
        case .none:
            FlagListViewModel.logger.error("LarkFlag: [CreateFlagItem] flag.key.key = .none")
            return nil
        case .some(_):
            FlagListViewModel.logger.error("LarkFlag: [CreateFlagItem] flag.key.key = .unknown")
            return nil
        @unknown default:
            FlagListViewModel.logger.error("LarkFlag: [CreateFlagItem] flag.key.key = .unknown")
            return nil
        }
        FlagListViewModel.logger.error("LarkFlag: [CreateFlagItem] flagItem = nil")
        return nil
    }

    func getFlagIdsBy(flags: [Feed_V1_FlagItem]) -> [String] {
        var flagIds: [String] = []
        flags.forEach { flagItem in
            var flagId: String = ""
            switch flagItem.key.key {
            case .feedPair(let feedPair):
                let feedId = String(feedPair.feedCardID)
                flagId = "feed_" + feedId
            case .messageID(let messageId):
                let msgId = String(messageId.messageID)
                flagId = "message_" + msgId
            case .none:
                flagId = ""
            case .some(_):
                flagId = ""
            default:
                flagId = ""
            }
            if !flagId.isEmpty {
                flagIds.append(flagId)
            }
        }
        return flagIds
    }

    func getChatIdsBy(chats: [Basic_V1_Chat]) -> [String] {
        let chatIds = chats.map { chat in
            return "chat_" + chat.id
        }
        return chatIds
    }

    func getChatterIdsBy(chatters: [Basic_V1_Chatter]) -> [String] {
        let chatterIds = chatters.map { chatter in
            return "chatter_" + chatter.id
        }
        return chatterIds
    }
}
