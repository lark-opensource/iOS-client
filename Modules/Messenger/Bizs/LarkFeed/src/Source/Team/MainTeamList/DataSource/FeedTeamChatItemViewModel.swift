//
//  FeedTeamChatItemViewModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/19.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LarkSDKInterface
import RustPB
import UniverseDesignToast
import ThreadSafeDataStructure
import RunloopTools
import LKCommonsLogging
import LarkPerf
import LarkModel
import LarkBizAvatar
import LarkBadge
import LarkFeedBase

struct FeedTeamChatItemViewModel {
    var chatItem: Basic_V1_Item
    var chatEntity: FeedPreview
    var isSelected = false
    var avatarId: String = "" // setAvatar时需要
    var badgeInfo: (type: BadgeType, style: LarkBadge.BadgeStyle)?
    var atBorderImage: UIImage? // At/At All border
    var channel = Basic_V1_Channel()

    init(item: Basic_V1_Item,
         chatEntity: FeedPreview) {
        self.chatItem = item
        self.chatEntity = chatEntity
        update()
    }

    private mutating func update() {
        badgeInfo = getBadgeInfo()
        atBorderImage = getAtBorderImage()
        channel = getChannel()
        avatarId = getAvatarId()
    }
}

extension FeedTeamChatItemViewModel {
    mutating func updateChatItem(item: Basic_V1_Item) {
        if isUpdateChatItem(newChatItem: item, oldChatItem: self.chatItem) {
            self.chatItem = item
        }
    }

    func isUpdateChatItem(newChatItem: Basic_V1_Item, oldChatItem: Basic_V1_Item) -> Bool {
        if newChatItem.version > oldChatItem.version {
            return true
        }
        return false
    }

    mutating func updateChatEntity(chatEntity: FeedPreview) {
        if isUpdateChatEntity(newChatEntity: chatEntity, oldChatEntity: self.chatEntity) {
            self.chatEntity = chatEntity
            update()
        }
    }

    func isUpdateChatEntity(newChatEntity: FeedPreview, oldChatEntity: FeedPreview) -> Bool {
        if newChatEntity.basicMeta.updateTime > oldChatEntity.basicMeta.updateTime {
            return true
        }
        return false
    }
}

extension FeedTeamChatItemViewModel {
    mutating func updateChatSelected(_ chatEntityId: String?) {
        let isSelected = chatEntity.id == chatEntityId
        updateChatSelected(isSelected)
    }

    mutating func updateChatSelected(_ isSelected: Bool) {
        self.isSelected = isSelected
    }

    mutating func updateBadgeStyle() {
        badgeInfo = getBadgeInfo()
    }
}

extension FeedTeamChatItemViewModel {
    private func getAvatarId() -> String {
        if chatEntity.preview.chatData.chatType == .p2P {
            return chatEntity.preview.chatData.chatterID
        }
        return chatEntity.id
    }

    private func getChannel() -> Basic_V1_Channel {
        var channelType: Basic_V1_Channel.TypeEnum = .unknown
        switch chatEntity.basicMeta.feedPreviewPBType {
        case .chat:
            channelType = .chat
        case .docFeed:
            channelType = .doc
        case .openapp:
            channelType = .openapp
        case .subscription:
            channelType = .subscription
        @unknown default:
            break
        }

        var channel = Basic_V1_Channel()
        channel.id = chatEntity.id
        channel.type = channelType
        return channel
    }

    private func getAtBorderImage() -> UIImage? {
        guard chatEntity.uiMeta.mention.hasAtInfo else { return nil }
        return chatEntity.uiMeta.mention.atInfo.type == .all ? Resources.feed_at_all_border : Resources.feed_at_me_border
    }

    private func getBadgeInfo() -> (type: BadgeType, style: LarkBadge.BadgeStyle)? {
        let unreadCount = chatEntity.basicMeta.unreadCount
        if unreadCount <= 0 {
            return nil
        }

        if chatEntity.basicMeta.isRemind {
            if chatEntity.basicMeta.feedCardBaseCategory == .done {
                return (.label(.number(unreadCount)), .middle)
            } else {
                return (.label(.number(unreadCount)), .strong)
            }
        } else {
            if chatEntity.basicMeta.feedCardBaseCategory == .done {
                return (.dot(.lark), .weak)
            } else {
                switch FeedBadgeBaseConfig.badgeStyle {
                case .weakRemind: return (.label(.number(unreadCount)), .weak)
                @unknown default: return (.dot(.lark), .strong)
                }
            }
        }
    }
}

extension FeedTeamChatItemViewModel {
    var description: String {
        return "chatItemModel_chatItem: \(chatItem.description), "
            + "chatItemModel_chatEntity: \(chatEntity.description), "
        + "teamChatType: \(chatEntity.chatFeedPreview?.teamEntity.teamsChatType), "
            + "isSelected: \(isSelected)"
    }
}

extension FeedTeamChatItemViewModel {
    func getLeftInset(mode: SwitchModeModule.Mode) -> CGFloat {
        switch mode {
        case .standardMode:
            return Cons.standardLeftInset
        case .threeBarMode(_):
            return Cons.threeBarLeftInset
        }
    }

    enum Cons {
        static let standardLeftInset: CGFloat = 36.0
        static let threeBarLeftInset: CGFloat = 16.0
    }
}
