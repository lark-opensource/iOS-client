//
//  TeaBizSceneModel.swift
//  LKCommonsTracker
//
//  Created by 夏汝震 on 2021/5/8.
//

import Foundation

public protocol TeaBizSceneProtocol {
    func toDict() -> [String: TeaDataType]
    // 业务场景公参加密
    var md5AllowList: [String] { get }
}

//  Tea平台不支持Bool类型，需要使用String类型 true -> "true"，false -> "false"
public protocol TeaDataType {}
extension String: TeaDataType {}
extension Float: TeaDataType {}
extension Int: TeaDataType {}

// MARK: - 消息场景公参
public struct TeaMessageSceneModel: TeaBizSceneProtocol {
    let messageId: String // 后端生成的正式消息ID
    let cid: String // 前端随机生成的消息ID
    let messageType: String // 消息类型

    public let md5AllowList = [String]()

    public init(
        messageId: String,
        cid: String,
        messageType: String) {
        self.messageId = messageId
        self.cid = cid
        self.messageType = messageType
    }

    public func toDict() -> [String: TeaDataType] {
        return [
            "msg_id": messageId,
            "cid": cid,
            "msg_type": messageType
        ]
    }
}

// MARK: - 会话场景公参
public struct TeaChatSceneModel: TeaBizSceneProtocol {
    let chatId: String // 会话标识
    let chatType: String // 会话类型
    let chatTypeDetail: String // 会话类型细分
    let memberType: String // 人员类型
    let isInnerGroup: String // 是否为内部群
    let isPublicGroup: String // 是否为公开群

    public var md5AllowList: [String] {
        return []
    }

    public init(
        chatId: String,
        chatType: String,
        chatTypeDetail: String,
        memberType: String,
        isInnerGroup: String,
        isPublicGroup: String) {
        self.chatId = chatId
        self.chatType = chatType
        self.chatTypeDetail = chatTypeDetail
        self.memberType = memberType
        self.isInnerGroup = isInnerGroup
        self.isPublicGroup = isPublicGroup
    }

    public func toDict() -> [String: TeaDataType] {
        return [
            "chat_id": chatId,
            "chat_type": chatType,
            "chat_type_detail": chatTypeDetail,
            "member_type": memberType,
            "is_inner_group": isInnerGroup,
            "is_public_group": isPublicGroup
        ]
    }
}

// MARK: - 话题场景公参
public struct TeaTopicSceneModel: TeaBizSceneProtocol {
    let threadId: String // 话题标示

    public let md5AllowList = [String]()

    public init(threadId: String) {
        self.threadId = threadId
    }

    public func toDict() -> [String: TeaDataType] {
        return [
            "thread_id": threadId
        ]
    }
}

// MARK: - 公司圈场景公参
public struct TeaCircleSceneModel: TeaBizSceneProtocol {
    let circleId: String // 前端随机生成的消息ID
    let categoryId: String // category_id
    let postId: String // 帖子标识
    let cid: String // 前端随机生成的消息ID

    public let md5AllowList = [String]()

    public init(
        circleId: String,
        categoryId: String,
        postId: String,
        cid: String) {
        self.circleId = circleId
        self.categoryId = categoryId
        self.postId = postId
        self.cid = cid
    }

    public func toDict() -> [String: TeaDataType] {
        return [
            "circle_id": circleId,
            "category_id": categoryId,
            "post_id": postId,
            "cid": cid,
        ]
    }
}

// MARK: - 文档场景公参
public struct TeaDocSceneModel: TeaBizSceneProtocol {
    let fileId: String // 文档id
    let fileType: String // 文档类型

    public var md5AllowList: [String] {
        return ["file_id"]
    }

    public init(
        fileId: String,
        fileType: String) {
        self.fileId = fileId
        self.fileType = fileType
    }

    public func toDict() -> [String: TeaDataType] {
        return [
            "file_id": fileId,
            "file_type": fileType
        ]
    }
}

// MARK: - 日历场景公参
public struct TeaCalSceneModel: TeaBizSceneProtocol {
    let viewType: String // 视图分布

    public let md5AllowList = [String]()

    public init(viewType: String) {
        self.viewType = viewType
    }

    public func toDict() -> [String: TeaDataType] {
        return [
            "view_type": viewType
        ]
    }
}

// MARK: - 日程场景公参
public struct TeaCalEventSceneModel: TeaBizSceneProtocol {
    let eventId: String // 日历&日程对应的id
    let fileId: String // 文档id
    let fileType: String // 文档类型
    let cardMessageType: String // 消息卡片类型
    let conferenceId: String // 会议id

    public var md5AllowList: [String] {
        return ["event_id", "file_id"]
    }

    public init(
        eventId: String,
        fileId: String,
        fileType: String,
        cardMessageType: String,
        conferenceId: String) {
        self.eventId = eventId
        self.fileId = fileId
        self.fileType = fileType
        self.cardMessageType = cardMessageType
        self.conferenceId = conferenceId
    }

    public func toDict() -> [String: TeaDataType] {
        return [
            "event_id": eventId,
            "file_id": fileId,
            "file_type": fileType,
            "card_message_type": cardMessageType,
            "conference_id": conferenceId
        ]
    }
}
