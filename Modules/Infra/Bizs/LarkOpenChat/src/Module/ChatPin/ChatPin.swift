//
//  ChatPin.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/5/12.
//

import Foundation
import LarkModel
import RustPB
import ThreadSafeDataStructure

public protocol ChatPinPayload {}

public class ChatPin {

    public let id: Int64
    public let type: RustPB.Im_V1_UniversalChatPin.TypeEnum
    public let chatId: Int64
    public let createTime: Int64
    /// 非固定列表中的顺序
    public var position: Int64
    /// 固定列表中的顺序
    public var topPosition: Int64
    /// 操作置顶的用户 chatter_id
    public let chatterID: Int64
    /// 操作固定到最前的用户 chatter_id
    public let topChatterID: Int64
    /// 是否被固定
    public var isTop: Bool {
        if _isTop {
            return true
        }
        switch queueType {
        case .topQueue:
            return true
        default:
            return false
        }
    }
    private let _isTop: Bool
    /// 是否是老置顶
    public var isOld: Bool {
        switch queueType {
        case .oldMsgQueue:
            return true
        default:
            return false
        }
    }
    private let queueType: RustPB.Im_V1_UniversalChatPin.QueueType
    public let unknownData: RustPB.Im_V1_UniversalChatPin.UnknownData

    public var pinChatter: Chatter? {
        get {
            return atomicExtra.value.pinChatter
        }
        set {
            atomicExtra.value.pinChatter = newValue
        }
    }

    public var topChatter: Chatter? {
        get {
            return atomicExtra.value.topChatter
        }
        set {
            atomicExtra.value.topChatter = newValue
        }
    }

    public var payload: ChatPinPayload? {
        get {
            return atomicExtra.value.payload
        }
        set {
            atomicExtra.value.payload = newValue
        }
    }

    struct PinExtra {
        var pinChatter: Chatter?
        var topChatter: Chatter?
        var payload: ChatPinPayload?
    }
    let atomicExtra: SafeAtomic<PinExtra> = PinExtra() + .unfairLock

    public init(id: Int64,
                type: RustPB.Im_V1_UniversalChatPin.TypeEnum,
                chatId: Int64,
                createTime: Int64,
                position: Int64,
                topPosition: Int64,
                chatterID: Int64,
                topChatterID: Int64,
                isTop: Bool,
                queueType: RustPB.Im_V1_UniversalChatPin.QueueType,
                unknownData: RustPB.Im_V1_UniversalChatPin.UnknownData) {
        self.id = id
        self.type = type
        self.chatId = chatId
        self.createTime = createTime
        self.position = position
        self.topPosition = topPosition
        self.chatterID = chatterID
        self.topChatterID = topChatterID
        self._isTop = isTop
        self.queueType = queueType
        self.unknownData = unknownData
    }

    public static func transform(pb: RustPB.Im_V1_UniversalChatPin) -> ChatPin {
        return ChatPin(
            id: pb.id,
            type: pb.type,
            chatId: pb.chatID,
            createTime: pb.createTime,
            position: pb.position,
            topPosition: pb.topPosition,
            chatterID: pb.chatterID,
            topChatterID: pb.topChatterID,
            isTop: pb.isTop,
            queueType: pb.queueType,
            unknownData: pb.unknownData
        )
    }
}

public enum UniversalChatPinPBModel {
    case unknown(Im_V1_UniversalChatPin.UnknownData)
    case messagePin(Im_V1_UniversalChatPin.MessagePin)
    case urlPin(Im_V1_UniversalChatPin.UrlPin)
    case announcementPin(Im_V1_UniversalChatPin.AnnouncementPin)
}

public struct UniversalChatPinsExtras {
    /// 消息卡片上携带的 Message 实体会从这里面去拿
    public let entity: Basic_V1_Entity
    /// preview_id -> preview
    /// URL 卡片上的预览数据会从这里去拿
    public let previewEntities: Dictionary<String,Basic_V1_UrlPreviewEntity>
    /// template_id -> template
    /// URL 卡片上的预览数据会从这里去拿
    public let previewTemplates: Dictionary<String,Basic_V1_URLPreviewTemplate>
    /// 群公告卡片上携带的数据
    public let announcement: Basic_V1_Chat.Announcement?

    public init(entity: Basic_V1_Entity,
                previewEntities: Dictionary<String,Basic_V1_UrlPreviewEntity>,
                previewTemplates: Dictionary<String,Basic_V1_URLPreviewTemplate>,
                announcement: Basic_V1_Chat.Announcement?) {
        self.entity = entity
        self.previewEntities = previewEntities
        self.previewTemplates = previewTemplates
        self.announcement = announcement
    }
}

public extension RustPB.Im_V1_UniversalChatPin {
    func convert() -> UniversalChatPinPBModel {
        switch self.type {
        case .unknown:
            return .unknown(unknownData)
        case .messagePin:
            return .messagePin(messagePinData)
        case .urlPin:
            return .urlPin(urlPinData)
        case .announcementPin:
            return .announcementPin(announcementPinData)
        @unknown default:
            return .unknown(unknownData)
        }
    }
}

public extension RustPB.Im_V1_GetUniversalChatPinsResponse {
    func getPinsExtras() -> UniversalChatPinsExtras {
        return UniversalChatPinsExtras(
            entity: entity,
            previewEntities: previewEntities,
            previewTemplates: previewTemplates,
            announcement: hasAnnouncement ? announcement : nil
        )
    }
}

public extension RustPB.Im_V1_PushUniversalChatPinOperation {
    func getPinsExtras() -> UniversalChatPinsExtras {
        return UniversalChatPinsExtras(
            entity: entity,
            previewEntities: previewEntities,
            previewTemplates: [:],
            announcement: hasAnnouncement ? announcement : nil
        )
    }
}

public extension RustPB.Im_V1_PushFirstScreenUniversalChatPins {
    func getPinsExtras() -> UniversalChatPinsExtras {
        return UniversalChatPinsExtras(
            entity: entity,
            previewEntities: previewEntities,
            previewTemplates: [:],
            announcement: hasAnnouncement ? announcement : nil
        )
    }
}
