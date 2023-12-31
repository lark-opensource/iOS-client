//
//  ChatFeedCardTagVM.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/5/30.
//

import Foundation
import LarkBizTag
import LarkContainer
import LarkCore
import LarkFeedBase
import LarkMessengerInterface
import LarkModel
import LarkOpenFeed
import RustPB

final class ChatFeedCardTagVM: FeedCardTagVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .tag
    }

    // VM 数据
    let tagBuilder: TagViewBuilder

    // 在子线程生成view data
    required init(feedPreview: FeedPreview, userResovler: UserResolver, dependency: ChatFeedCardDependency?) {
        let builder = FeedChatTagViewBuilder()
        if let dependency = dependency {
            var isConnect = false
            UserStyle.on(.connectTag, userType: dependency.accountType).apply(on: {
                isConnect = true
            }, off: {})

            var isExternal = false
            UserStyle.on(.externalTag, userType: dependency.accountType).apply(on: {
                isExternal = true
            }, off: {})

            builder.reset(with: [])
            let chat = feedPreview.preview.chatData
            builder.isCrypto(chat.isCrypto)
                .isPrivateMode(chat.isPrivateMode)
                .isDoNotDisturb(chat.chatType == .p2P && dependency.afterThatServerTime(time: Int64(chat.doNotDisturbEndTime))) // 判断勿chat模式，单聊才显示勿扰
                .isOfficial(chat.isOfficialOncall || chat.tags.contains(.official))
                .isRobot(chat.hasWithBotTag && !chat.withBotTag.isEmpty)
                .isOncallOffline(chat.hasOncallID && !chat.oncallID.isEmpty && chat.isOfflineOncall)
                .isOncall(chat.hasOncallID && !chat.oncallID.isEmpty)
                .isConnected(chat.isCrossWithKa && isConnect)
                .isExternal(feedPreview.extraMeta.crossTenant && isExternal)
                .isPublic(chat.isPublicV2)
            builder.addTags(with: Basic_V1_TagData.transform(tagDataItems: feedPreview.uiMeta.tagDataItems))

            if !isCustomer(tenantId: dependency.currentTenantId) { // C端用户
                builder.isTeam(chat.isDepartment)
                    .isAllStaff(chat.tenantChat)
                    .isSuperChat(chat.isSuper)
            }
        }
        self.tagBuilder = builder
    }
}
