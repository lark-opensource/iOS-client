//
//  ReactionDetailModel.swift
//  LarkReactionDetailController
//
//  Created by 李晨 on 2019/6/16.
//

import Foundation

open class Message {
    public let id: String
    public let channelID: String

    public init(id: String, channelID: String) {
        self.id = id
        self.channelID = channelID
    }
}

public struct Chatter {

    public enum DescriptionType {
        case onDefault
        /// 出差
        case onBusiness
        /// 请假
        case onLeave
        /// 开会
        case onMeeting
    }

    public enum ChatterType {
        /// 实名
        case user
        /// 花名
        case nickName
        /// 匿名
        case anonymous
    }

    public let id: String
    public let avatarKey: String
    public let displayName: String
    public let descriptionText: String
    public let descriptionType: DescriptionType
    public let chatterType: ChatterType

    public init(
        id: String,
        avatarKey: String,
        displayName: String,
        descriptionText: String,
        descriptionType: DescriptionType
    ) {
        self.init(id: id, avatarKey: avatarKey, displayName: displayName, descriptionText: descriptionText, descriptionType: descriptionType, chatterType: .user)
    }

    public init(
        id: String,
        avatarKey: String,
        displayName: String,
        descriptionText: String,
        descriptionType: DescriptionType,
        chatterType: ChatterType
    ) {
        self.id = id
        self.avatarKey = avatarKey
        self.displayName = displayName
        self.descriptionText = descriptionText
        self.descriptionType = descriptionType
        self.chatterType = chatterType
    }
}

public struct Reaction {
    public let type: String
    public let chatterIds: [String]
    public let totalCount: Int? // reaction的chatterIds可能涉及分页加载问题，或者一上来拿不到chatterIds，如果外部直接指定了总数，优先使用指定值

    public init(type: String, chatterIds: [String]) {
        self.type = type
        self.chatterIds = chatterIds
        self.totalCount = nil
    }

    public init(type: String, chatterIds: [String], totalCount: Int?) {
        self.type = type
        self.chatterIds = chatterIds
        self.totalCount = totalCount
    }
}

func excuteInMain(_ callback: () -> Void) {
    if Thread.isMainThread {
        callback()
    } else {
        DispatchQueue.main.sync {
            callback()
        }
    }
}
