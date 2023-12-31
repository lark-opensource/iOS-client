//
//  ForwardItemDataConvertable.swift
//  LarkSearchCore
//
//  Created by Yuri on 2022/7/4.
//

import Foundation
import RustPB
import LarkMessengerInterface
import LarkAccountInterface
import LarkModel
import LarkContainer

class ForwardItemDataConverter {
    static func convert(chatter: LarkModel.Chatter, currentTeanantId: String, chatId: String? = nil) -> ForwardItem {
        return ForwardItem(avatarKey: chatter.avatarKey,
                           name: chatter.name,
                           subtitle: chatter.anotherName,
                           description: "",
                           descriptionType: chatter.description_p.type,
                           localizeName: chatter.localizedName,
                           id: chatter.id,
                           chatId: chatId,
                           type: .user,
                           isCrossTenant: chatter.tenantId != currentTeanantId,
                           isCrypto: false,
                           isThread: false,
                           doNotDisturbEndTime: 0,
                           hasInvitePermission: false,
                           userTypeObservable: nil,
                           enableThreadMiniIcon: false,
                           isOfficialOncall: false)
    }

    static func convert(chat: LarkModel.Chat, currentTeanantId: String) -> ForwardItem {
        let type = chat.isPrivateMode ? .chat : (chat.chatterId.isEmpty ? .chat : ForwardItemType(rawValue: chat.chatter?.type.rawValue ?? 0) ?? .unknown)
        var item = ForwardItem(avatarKey: chat.avatarKey,
                               name: chat.name,
                               subtitle: chat.chatter?.department ?? "",
                               description: chat.description,
                               descriptionType: chat.chatter?.description_p.type ?? .onDefault,
                               localizeName: chat.localizedName,
                               id: chat.id,
                               chatId: chat.id,
                               type: .chat,
                               isCrossTenant: chat.isCrossTenant,
                               isCrypto: chat.isCrypto,
                               isThread: chat.chatMode == .threadV2 || type.isThread,
                               doNotDisturbEndTime: 0,
                               hasInvitePermission: false,
                               userTypeObservable: nil,
                               enableThreadMiniIcon: false,
                               isOfficialOncall: chat.isOfficialOncall)
        item.chatterId = chat.chatterId
        return item
    }
}

protocol ForwardItemDataConvertable {
    func convert(previews: [RustPB.Feed_V1_FeedEntityPreview], userService: PassportUserService?) -> [ForwardItem]
    func convert(preview: RustPB.Feed_V1_FeedEntityPreview, userService: PassportUserService?) -> ForwardItem?
    func generateRecentForwardRequestParameter(currentUid: String, filter: ForwardItemFilter?, filterParameters: ForwardFilterParameters?) -> RecentForwardFilterParameter
    func generateRecentForwardRequestParameter(filterConfigs: IncludeConfigs?, disabledConfigs: IncludeConfigs?) -> RecentForwardFilterParameter
    func convertIncludeConfigs(includeConfigs: IncludeConfigs?) -> [Feed_V1_GetRecentVisitTargetsRequest.IncludeItem]
}

extension ForwardItemDataConvertable {
    func convert(previews: [RustPB.Feed_V1_FeedEntityPreview], userService: PassportUserService?) -> [ForwardItem] {
        return previews.compactMap { convert(preview: $0, userService: userService) }
    }
    func convert(preview: RustPB.Feed_V1_FeedEntityPreview, userService: PassportUserService?) -> ForwardItem? {
        switch preview.extraData {
        case .chatData(let chat):
            let isMyAi = chat.chatterType == .ai
            let isGroupChat = chat.chatType == .group
            let isBot = chat.chatterType == .bot
            var item = ForwardItem(
                avatarKey: chat.avatarKey,
                name: chat.name,
                subtitle: "", // ????
                description: chat.chatDescription,
                descriptionType: .onDefault,
                localizeName: chat.localizedDigestMessage,
                id: isGroupChat ? preview.feedID : chat.chatterID,
                chatId: preview.feedID,
                type: isMyAi ? .myAi : (isGroupChat ? .chat : (isBot ? .bot : .user)),
                isCrossTenant: chat.crossTenant,
                isCrossWithKa: chat.isCrossWithKa,
                isCrypto: chat.isCrypto,
                isThread: chat.chatMode == .threadV2,
                isPrivate: chat.isPrivateMode,
                channelID: nil,
                doNotDisturbEndTime: chat.doNotDisturbEndTime,
                hasInvitePermission: true,
                userTypeObservable: userService?.state.map { $0.user.type } ?? .never(),
                enableThreadMiniIcon: false,
                isOfficialOncall: chat.isOfficialOncall,
                tags: chat.tags,
                customStatus: chat.chatterStatus.topActive,
                tagData: chat.tagInfo
            )
            item.avatarId = isGroupChat ? preview.feedID : chat.chatterID
            if chat.isPrivateMode {
                item.id = preview.feedID
                item.type = .chat
            }
            item.chatUserCount = chat.userCount
            item.isUserCountVisible = chat.isUserCountVisible
            return item
        case .threadData(let thread):
            var item = ForwardItem(
                avatarKey: thread.avatarKey,
                name: thread.name,
                subtitle: "",
                description: "",
                descriptionType: .onDefault,
                localizeName: thread.localizedDigestMessage,
                id: preview.feedID,
                chatId: thread.chatID,
                type: thread.entityType == .msgThread ? .replyThreadMessage : .threadMessage,
                isCrossTenant: false,
                isCrossWithKa: false,
                isCrypto: false,
                isThread: true,
                channelID: thread.chatID,
                doNotDisturbEndTime: 0,
                hasInvitePermission: true,
                userTypeObservable: userService?.state.map { $0.user.type } ?? .never(),
                enableThreadMiniIcon: false,
                isOfficialOncall: false,
                tags: [],
                customStatus: nil
            )
            let isGroupChat = thread.chatterID.isEmpty
            item.avatarId = isGroupChat ? thread.chatID : thread.chatterID
            return item
        @unknown default: return nil
        }
    }

    private func generateRecentForwardParam(fromDisabled config: IncludeConfigs?) -> RecentForwardFilterParameter {
        // 置灰参数为nil，返回默认最近转发参数
        guard let config = config else { return RecentForwardFilterParameter() }
        var includeGroupChat = false
        var includeP2PChat = false
        var includeThreadChat = false
        var includeOuterChatter = false
        var includeOuterChat = false
        var includeSelf = false
        var includeMyAi = false
        let chatters: [ForwardUserEnabledEntityConfig] = config.getEntities()
        let chats: [ForwardGroupChatEnabledEntityConfig] = config.getEntities()
        let myAis: [ForwardMyAiEnabledEntityConfig] = config.getEntities()
        if let chatterConfig = chatters.first {
            includeP2PChat = true
            switch chatterConfig.tenant {
            case .all, .outer:
                //如果业务枚举配置为outer，需要置灰内部人，仅能与外部人交互；
                //此时理论上应该在最近转发中过滤内部人，才能让最近转发和近期访问表现一致
                // FIXME: 最近转发接口不支持单独过滤内部人，所以这里只能先这样写,后续最近转发pb接口参数应对齐最近访问
                includeOuterChatter = true
            case.inner:
                includeOuterChatter = false
            default:
                break
            }
            switch chatterConfig.selfType {
            case .all, .me:
                // FIXME: 最近转发接口不支持单独过滤其他人
                includeSelf = true
            case .other:
                includeSelf = false
            default:
                break
            }
        }
        if let chatConfig = chats.first {
            includeGroupChat = true
            switch chatConfig.tenant {
            case .all, .outer:
                // FIXME: 最近转发接口不支持单独过滤内部群
                includeOuterChat = true
            case .inner:
                includeOuterChat = false
            default:
                break
            }
            switch chatConfig.chatType {
            case .all, .thread:
                // FIXME: 最近转发接口不支持单独过滤普通群
                includeThreadChat = true
            case.normal:
                includeThreadChat = false
            default:
                break
            }
        }
        if !myAis.isEmpty { includeMyAi = true }

        return RecentForwardFilterParameter(includeGroupChat: includeGroupChat,
                                            includeP2PChat: includeP2PChat,
                                            includeThreadChat: includeThreadChat,
                                            // 从严判断外部权限，只要外部人和外部群有一个配置为false，最近转发过滤外部实体的参数就为false
                                            includeOuterChat: includeOuterChat && includeOuterChatter,
                                            includeSelf: includeSelf,
                                            includeMyAi: includeMyAi)
    }

    private func generateRecentForwardParam(fromFilter config: IncludeConfigs?) -> RecentForwardFilterParameter {
        // 过滤参数为nil，返回默认最近转发参数
        guard let config = config else { return RecentForwardFilterParameter() }
        var includeGroupChat = false
        var includeP2PChat = false
        var includeThreadChat = false
        // 是否展示外部人
        var includeOuterChatter = false
        // 是否展示外部群
        var includeOuterChat = false
        var includeSelf = false
        // 是否展示Myai
        var includeMyAi = false

        let chatters: [ForwardUserEntityConfig] = config.getEntities()
        let chats: [ForwardGroupChatEntityConfig] = config.getEntities()
        let myAis: [ForwardMyAiEntityConfig] = config.getEntities()

        if let chatterConfig = chatters.first {
            includeP2PChat = true
            includeSelf = true
            switch chatterConfig.tenant {
            case .all, .outer:
                // FIXME: 最近转发接口不支持单独过滤内部人，所以这里只能先这样写,后续最近转发pb接口参数应对齐最近访问
                includeOuterChatter = true
            case.inner:
                includeOuterChatter = false
            default:
                break
            }
        }
        if let chatConfig = chats.first {
            includeGroupChat = true
            includeThreadChat = true
            switch chatConfig.tenant {
            case .all, .outer:
                // FIXME: 最近转发接口不支持单独过滤内部群
                includeOuterChat = true
            case .inner:
                includeOuterChat = false
            default:
                break
            }
        }
        if !myAis.isEmpty { includeMyAi = true }

        return RecentForwardFilterParameter(includeGroupChat: includeGroupChat,
                                            includeP2PChat: includeP2PChat,
                                            includeThreadChat: includeThreadChat,
                                            // 从严判断外部权限，只要外部人和外部群有一个配置为false，最近转发过滤外部实体的参数就为false
                                            includeOuterChat: includeOuterChat && includeOuterChatter,
                                            includeSelf: includeSelf,
                                            includeMyAi: includeMyAi)
    }

    // 根据推荐搜索的置灰参数和过滤参数决定最近转发参数
    // 若推荐搜索需要置灰或过滤某实体，那在最近转发也过滤它
    func generateRecentForwardRequestParameter(filterConfigs: IncludeConfigs?, disabledConfigs: IncludeConfigs?) -> RecentForwardFilterParameter {
        let paramFromFilter = generateRecentForwardParam(fromFilter: filterConfigs)
        let paramFromDisable = generateRecentForwardParam(fromDisabled: disabledConfigs)
        return RecentForwardFilterParameter(includeGroupChat: paramFromFilter.includeGroupChat && paramFromDisable.includeGroupChat,
                                            includeP2PChat: paramFromFilter.includeP2PChat && paramFromDisable.includeP2PChat,
                                            includeThreadChat: paramFromFilter.includeThreadChat && paramFromDisable.includeThreadChat,
                                            // 从严判断外部权限，只要外部人和外部群有一个配置为false，最近转发过滤外部实体的参数就为false
                                            includeOuterChat: paramFromFilter.includeOuterChat && paramFromDisable.includeOuterChat,
                                            includeSelf: paramFromFilter.includeSelf && paramFromDisable.includeSelf,
                                            includeMyAi: paramFromFilter.includeMyAi && paramFromDisable.includeMyAi)
    }

    func generateRecentForwardRequestParameter(currentUid: String, filter: ForwardItemFilter?, filterParameters: ForwardFilterParameters?) -> RecentForwardFilterParameter {
        // 需要从自定义过滤器中知道过滤参数，因此构建一个item对象试探filter的表现
        var item = ForwardItem(avatarKey: "",
                               name: "",
                               subtitle: "", description: "",
                               descriptionType: .onDefault, localizeName: "",
                               id: currentUid, type: .user,
                               isCrossTenant: false,
                               isCrossWithKa: false,
                               isCrypto: false, isThread: false,
                               doNotDisturbEndTime: 0, hasInvitePermission: false,
                               userTypeObservable: nil, enableThreadMiniIcon: false,
                               isOfficialOncall: false, tags: [])
        let includeSelf = filter?(item) ?? true
        item.id = ""
        let includeP2PChat = filter?(item) ?? true
        item.type = .chat
        let includeGroupChat = filter?(item) ?? true

        var includeOuterChat = true
        if let outerChat = filterParameters?.includeOuterChat {
            includeOuterChat = outerChat
        } else {
            item.isCrossTenant = true
            includeOuterChat = filter?(item) ?? true
        }

        var includeThreadChat = true
        if let includeThread = filterParameters?.includeThread {
            includeThreadChat = includeThread
        } else {
            item.isCrossTenant = false
            item.type = .chat
            item.isThread = true
            includeThreadChat = filter?(item) ?? true
        }
        let param = RecentForwardFilterParameter(includeGroupChat: includeGroupChat,
                                           includeP2PChat: includeP2PChat,
                                           includeThreadChat: includeThreadChat,
                                           includeOuterChat: includeOuterChat,
                                           includeSelf: includeSelf)
        return param
    }

    func convertIncludeConfigs(includeConfigs: IncludeConfigs?) -> [Feed_V1_GetRecentVisitTargetsRequest.IncludeItem] {
        var configs = [Feed_V1_GetRecentVisitTargetsRequest.IncludeItem]()
        guard let includeConfigs = includeConfigs else { return configs }
        let chatters: [ForwardUserEntityConfig] = includeConfigs.getEntities()
        let chats: [ForwardGroupChatEntityConfig] = includeConfigs.getEntities()
        let bots: [ForwardBotEntityConfig] = includeConfigs.getEntities()
        let threads: [ForwardThreadEntityConfig] = includeConfigs.getEntities()
        let myAis: [ForwardMyAiEntityConfig] = includeConfigs.getEntities()

        if let userConfig = chatters.first {
            var includeItem = Feed_V1_GetRecentVisitTargetsRequest.IncludeItem()
            includeItem.config = .userConfigs(includeItem.userConfigs)

            switch userConfig.tenant {
            case .outer:
                includeItem.userConfigs.tenantCondition = .crossTenant
            case .inner:
                includeItem.userConfigs.tenantCondition = .notCrossTenant
            case .all:
                includeItem.userConfigs.tenantCondition = .allTenant
            }
            //转发默认展示聊过用户(Feed数据都是聊过的)
            includeItem.userConfigs.talkedStatusCondition = .allTalked
            //转发默认展示在职用户
            includeItem.userConfigs.workStatusCondition = .notResigned
            //转发默认不过滤自己，对齐转发搜索
            includeItem.userConfigs.userTypeCondition = .allUser
            configs.append(includeItem)
        }
        if let groupChatConfig = chats.first {
            var includeItem = Feed_V1_GetRecentVisitTargetsRequest.IncludeItem()
            includeItem.config = .groupChatConfigs(includeItem.groupChatConfigs)
            switch groupChatConfig.tenant {
            case .outer:
                includeItem.groupChatConfigs.tenantCondition = .crossTenant
            case .inner:
                includeItem.groupChatConfigs.tenantCondition = .notCrossTenant
            case .all:
                includeItem.groupChatConfigs.tenantCondition = .allTenant
            }
            //转发默认展示所有类型群聊，对齐转发搜索
            includeItem.groupChatConfigs.groupChatTypeCondition = .allChat
            includeItem.groupChatConfigs.publicTypeCondition = .allStatus
            includeItem.groupChatConfigs.shieldTypeCondition = .all
            configs.append(includeItem)
        }
        if let botConfig = bots.first {
            var includeItem = Feed_V1_GetRecentVisitTargetsRequest.IncludeItem()
            includeItem.config = .botConfigs(includeItem.botConfigs)
            configs.append(includeItem)
        }
        if let threadConfig = threads.first {
            var includeItem = Feed_V1_GetRecentVisitTargetsRequest.IncludeItem()
            includeItem.config = .threadConfigs(includeItem.threadConfigs)
            //默认展示所有类型话题
            includeItem.threadConfigs.publicTypeCondition = .allStatus
            includeItem.threadConfigs.threadTypeCondition = .allThread
            //默认不区分内外部话题
            includeItem.threadConfigs.tenantCondition = .allTenant
            configs.append(includeItem)
        }
        if !myAis.isEmpty {
            var includeItem = Feed_V1_GetRecentVisitTargetsRequest.IncludeItem()
            includeItem.config = .myAiConfigs(includeItem.myAiConfigs)
            configs.append(includeItem)
        }
        return configs
    }
}
