//
//  LarkNSEExtra.swift
//  LarkNotificationServiceExtension
//
//  Created by mochangxing on 2019/8/30.
//
// swiftlint:disable all
import Foundation

public enum LarkNSExtensionBizType: String, CaseIterable {
    case lark
    case docs
    case mail
    case voip
    case vc
    case calendar
    case todo
    case openAppChat = "openapp_chat"
    case openMicroApp = "subscriptions_news"
    case unkonwn
}

public enum PushDirectType: Int {
    case pushToDefault = 1 //什么也不做，只是打开app
    case pushToLatestUnreadMessge = 2 //跳转会话的最新一条未读消
    case pushToMessage = 3 //跳转到特定消息
    case pushToDocPhotoSelector = 4 //doc 选图专用
    case pushToChatContact = 5 //跳转到联系人页面
}

public enum PushBadgeType: Int {
    case clientNochanged = 0
    case clientPlusOne = 1
    case serverPush = 2
}

public enum PushChannel: String {
    case chat
    case thread
    case msg_thread
    case unkonwn
}

public struct LarkNSEExtra: JSONCodable {
    public let Sid: String
    public let time: UInt64
    public let direct: PushDirectType
    public let command: Int
    public let contentMutable: Bool
    public let mutableBadge: Bool
    public let notIncreaceBadge: Bool
    public let chatId: Int64?
    public let userId: String?
    public let position: Int32?
    public let threadId: Int64?
    public let messageID: Int64?
    public let originDict: [String: Any]
    public let extraString: String?
    public let quickReply: Int32?
    public let imageUrl: String?
    public let channel: PushChannel?
    public let biz: LarkNSExtensionBizType?
    public let isRecall: Bool
    public let isUrgent: Bool
    public let isShowDetail: Bool
    public let chatDigestId: String
    public let senderDigestId: String
    public let senderName: String
    public let groupName: String
    public let tenantName: String
    public let isReply: Bool
    public let groupSize: Int
    public let isMentioned: Bool
    public let pruneOutline: Bool
    public let isNotComm: Bool
    public let messageType: Int64
    public let soundUrl: String?
    /// 该字段来自端上使用，不从接口下发，标记是remote or local notification
    public let isRemote: Bool

    public init(Sid: String, 
                time: UInt64,
                direct: PushDirectType,
                command: Int,
                contentMutable: Bool,
                mutableBadge: Bool,
                notIncreaceBadge: Bool,
                chatId: Int64?,
                userId: String?,
                position: Int32?,
                threadId: Int64?,
                messageID: Int64?,
                originDict: [String: Any],
                extraString: String? = nil,
                quickReply: Int32?,
                imageUrl: String?,
                channel: PushChannel?,
                biz: LarkNSExtensionBizType?,
                isRecall: Bool,
                isUrgent: Bool,
                isShowDetail: Bool,
                chatDigestId: String,
                senderDigestId: String,
                senderName: String,
                groupName: String,
                tenantName: String,
                isReply: Bool,
                groupSize: Int,
                isMentioned: Bool,
                pruneOutline: Bool,
                isNotComm: Bool,
                messageType: Int64,
                soundUrl: String? = nil,
                isRemote: Bool) {
        self.Sid = Sid
        self.time = time
        self.direct = direct
        self.command = command
        self.contentMutable = contentMutable
        self.mutableBadge = mutableBadge
        self.notIncreaceBadge = notIncreaceBadge
        self.chatId = chatId
        self.userId = userId
        self.position = position
        self.threadId = threadId
        self.messageID = messageID
        self.originDict = originDict
        self.extraString = extraString
        self.quickReply = quickReply
        self.imageUrl = imageUrl
        self.channel = channel
        self.biz = biz
        self.isRecall = isRecall
        self.isUrgent = isUrgent
        self.isShowDetail = isShowDetail
        self.chatDigestId = chatDigestId
        self.senderDigestId = senderDigestId
        self.senderName = senderName
        self.groupName = groupName
        self.tenantName = tenantName
        self.isReply = isReply
        self.groupSize = groupSize
        self.isMentioned = isMentioned
        self.pruneOutline = pruneOutline
        self.isNotComm = isNotComm
        self.messageType = messageType
        self.soundUrl = soundUrl
        self.isRemote = isRemote
    }

    public init?(dict: [String: Any]) {
        guard let Sid = dict["Sid"] as? String,
              let time = dict["Time"] as? UInt64,
              let dirct = dict["direct"] as? Int,
              let contentMutable = dict["mutable_content"] as? Bool,
              let mutableBadge = dict["mutable_badge"] as? Bool else {
                return nil
        }
        self.Sid = Sid
        self.time = time
        self.direct = PushDirectType(rawValue: dirct) ?? .pushToDefault
        self.mutableBadge = mutableBadge
        self.command = dict["command"] as? Int ?? -1
        self.messageType = dict["message_type"] as? Int64 ?? -1
        self.notIncreaceBadge = dict["not_incr_badge"] as? Bool ?? false
        self.contentMutable = contentMutable
        self.chatId = dict["chat_id"] as? Int64
        self.userId = dict["target_user_id"] as? String
        self.position = dict["position"] as? Int32
        self.threadId = dict["thread_id"] as? Int64
        self.messageID = dict["message_id"] as? Int64
        self.extraString = dict["extra_str"] as? String
        self.quickReply = dict["quick_reply_category"] as? Int32

        if let imageUrl = dict["image_url"] as? String,
           let decodedData = Data(base64Encoded: imageUrl),
           let decodedString = String(data: decodedData, encoding: .utf8) {
            self.imageUrl = decodedString
        } else {
            self.imageUrl = nil
        }

        self.channel = (dict["channel"] as? String).map { PushChannel(rawValue: $0) } ?? .unkonwn
        self.biz = (dict["biz"] as? String).map { LarkNSExtensionBizType(rawValue: $0) } ?? .unkonwn
        self.isRecall = dict["is_recall"] as? Bool ?? false
        self.isUrgent = dict["is_urgent"] as? Bool ?? false
        self.isShowDetail = dict["is_show_detail"] as? Bool ?? true
        self.chatDigestId = dict["chat_digest_id"] as? String ?? ""
        self.senderDigestId = dict["sender_digest_id"] as? String ?? ""
        self.senderName = dict["sender_name"] as? String ?? ""
        self.groupName = dict["channel_name"] as? String ?? ""
        self.tenantName = dict["tenant_name"] as? String ?? ""
        self.groupSize = dict["channel_size"] as? Int ?? 100
        self.isReply = dict["is_reply"] as? Bool ?? false
        self.isMentioned = dict["is_mentioned"] as? Bool ?? false
        self.pruneOutline = dict["prune_outline"] as? Bool ?? false
        self.isNotComm = dict["not_comm_notification"] as? Bool ?? true
        self.soundUrl = dict["sound_url"] as? String
        self.isRemote = dict["is_remote"] as? Bool ?? true
        self.originDict = dict
    }

    static public func getExtraDict(from userInfo: [AnyHashable: Any]) -> LarkNSEExtra? {
        if let extraString = userInfo["extra_str"] as? String, let data = extraString.data(using: .utf8) {
            do {
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    return nil
                }
                return LarkNSEExtra(dict: dict)

            } catch {
            }
        }
        return nil
    }

    static public func extraToString(from extra: LarkNSEExtra?) -> String? {
        guard let extra = extra else {
            return nil
        }
        let dict = extra.toDict()
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    public func toDict() -> [String: Any] {
        var dict: [String: Any] = [:]

        dict["Sid"] = self.Sid
        dict["Time"] = self.time
        dict["direct"] = self.direct.rawValue
        dict["mutable_content"] = self.contentMutable
        dict["mutable_badge"] = self.mutableBadge
        dict["command"] = self.command
        dict["message_type"] = self.messageType
        dict["not_incr_badge"] = self.notIncreaceBadge
        dict["chat_id"] = self.chatId
        dict["target_user_id"] = self.userId
        dict["position"] = self.position
        dict["thread_id"] = self.threadId
        dict["message_id"] = self.messageID
        dict["extra_str"] = self.extraString
        dict["quick_reply_category"] = self.quickReply

        if let imageUrl = self.imageUrl,
           let urlData = imageUrl.data(using: .utf8) {
            dict["image_url"] = urlData.base64EncodedString()
        }

        dict["channel"] = self.channel?.rawValue
        dict["biz"] = self.biz?.rawValue
        dict["is_recall"] = self.isRecall
        dict["chat_digest_id"] = self.chatDigestId
        dict["senderDigestId"] = self.senderDigestId

        dict["sender_name"] = self.senderName
        dict["channel_name"] = self.groupName
        dict["tenant_name"] = self.tenantName
        dict["channel_size"] = self.groupSize
        dict["is_reply"] = self.isReply
        dict["is_urgent"] = self.isUrgent
        dict["is_show_detail"] = self.isShowDetail
        dict["is_mentioned"] = self.isMentioned
        dict["prune_outline"] = self.pruneOutline
        dict["not_comm_notification"] = self.isNotComm
        dict["sound_url"] = self.soundUrl ?? ""
        dict["is_remote"] = self.isRemote

        return dict
    }
}

// swiftlint:enable all
