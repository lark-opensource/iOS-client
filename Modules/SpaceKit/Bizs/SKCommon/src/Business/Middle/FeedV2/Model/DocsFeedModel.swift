//
//  DocsFeedModel.swift
//  SpaceKit
//
//  Created by Ryan on 2018/10/22.
//  swiftlint:disable cyclomatic_complexity type_body_length function_body_length

import UIKit
import SwiftyJSON
import SKFoundation
import SKUIKit
import SKResource
import SpaceInterface
import SKInfra

// 为什么要用Entity包一层呢？历史遗留，其实最新版本可以直接用message就行了，
// 但是呢，一个人做消息、评论、成功率性能、包体积性能，没时间改
//public class NewEntity: NSObject, NSSecureCoding {
//
//    public static var supportsSecureCoding: Bool { return true }
//
//    public enum NewEntityType: String {
//        case whole
//        case card
//        case mention
//        case share
//        case undefined
//    }
//    /// 标识一个section，全文评论为最早消息的messageID，@为mentionID，卡片为commentID
//    public var id: String = ""
//    /// 标识一个section的类型，全文评论、卡片评论、@
//    public var type: NewEntityType = .card
//    /// 折叠起来的消息数
//    public var foldMessageCount: Int = 0
//    /// 包含未读数
//    public var unReadMessageCount: Int = 0
//    /// 是否原文已删
//    public var isLocalDelete: Bool = false
//    /// 是否已被解决
//    public var isResolve: Bool = false
//    /// 引用内容
//    public var quote: String = ""
//
//    /// 展开显示时的Messages
//    public var showMessages: [NewMessage] = []
//
//    override public init() {
//        super.init()
//    }
//
//    public func encode(with coder: NSCoder) {
//        coder.encode(id, forKey: "id")
//        coder.encode(type.rawValue, forKey: "type")
//        coder.encode(foldMessageCount, forKey: "foldMessageCount")
//        coder.encode(unReadMessageCount, forKey: "unReadMessageCount")
//        coder.encode(isLocalDelete, forKey: "isLocalDelete")
//        coder.encode(isResolve, forKey: "isResolve")
//        coder.encode(quote, forKey: "quote")
//        coder.encode(showMessages, forKey: "showMessages")
//    }
//
//    required public init?(coder: NSCoder) {
//        id = coder.decodeObject(forKey: "id") as? String ?? ""
//        type = NewEntityType(rawValue: coder.decodeObject(forKey: "type") as? String ?? "") ?? .card
//        foldMessageCount = coder.decodeInteger(forKey: "foldMessageCount")
//        unReadMessageCount = coder.decodeInteger(forKey: "unReadMessageCount")
//        isLocalDelete = coder.decodeBool(forKey: "isLocalDelete")
//        isResolve = coder.decodeBool(forKey: "isResolve")
//        quote = coder.decodeObject(forKey: "quote") as? String ?? ""
//        showMessages = coder.decodeObject(of: [NSArray.self, NewMessage.self], forKey: "showMessages") as? [NewMessage] ?? []
//    }
//}

public final class NewMessage: NSObject, NSSecureCoding {

    public static var supportsSecureCoding: Bool { return true }

    override public init() {
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(messageID, forKey: "messageID")
        coder.encode(commentID, forKey: "commentID")
        coder.encode(replyID, forKey: "replyID")
        coder.encode(mentionID, forKey: "mentionID")
        coder.encode(type.rawValue, forKey: "type")
        coder.encode(status.rawValue, forKey: "status")
        coder.encode(avatarURL, forKey: "avatarURL")
        coder.encode(name, forKey: "name")
        coder.encode(createTime, forKey: "createTime")
        coder.encode(related, forKey: "related")
        coder.encode(userID, forKey: "userID")
        coder.encode(mentionString, forKey: "mentionString")
        coder.encode(commentAttributedText, forKey: "commentAttributedText")
        coder.encode(quoteAttributedText, forKey: "quoteAttributedText")
        coder.encode(content, forKey: "content")
        coder.encode(commentCreateTime, forKey: "commentCreateTime")
        coder.encode(commentUpdateTime, forKey: "commentUpdateTime")
        coder.encode(quote, forKey: "quote")
        coder.encode(isWhole, forKey: "isWhole")
        coder.encode(finish, forKey: "finish")
        coder.encode(modify, forKey: "modify")
        coder.encode(translateContent, forKey: "translateContent")
        coder.encode(localDelete, forKey: "localDelete")
        coder.encode(translateStatus?.rawValue, forKey: "translateStatus")
        coder.encode(countNumber, forKey: "countNumber")
        coder.encode(docType.rawValue, forKey: "docType")
        coder.encode(shouldShowCountNumber, forKey: "shouldShowCountNumber")
        coder.encode(audioDuration, forKey: "audioDuration")
        coder.encode(audioFileToken, forKey: "audioFileToken")
        coder.encode(reactionType, forKey: "reactionType")
        coder.encode(tempContent, forKey: "tempContent")
        coder.encode(tempTransContent, forKey: "tempTransContent")
        coder.encode(isHandled, forKey: "isHandled")
        coder.encode(commentDelete, forKey: "commentDelete")
        coder.encode(commentMention, forKey: "commentMention")
        coder.encode(replyIndex, forKey: "replyIndex")
        coder.encode(subType.rawValue, forKey: "subType")
        coder.encode(likeCount, forKey: "likeCount")
        coder.encode(likeUsers, forKey: "likeUsers")
        coder.encode(emojiKey, forKey: "emojiKey")
    }

    required public init?(coder: NSCoder) {
        messageID = coder.decodeObject(forKey: "messageID") as? String ?? ""
        commentID = coder.decodeObject(forKey: "commentID") as? String ?? ""
        replyID = coder.decodeObject(forKey: "replyID") as? String ?? ""
        mentionID = coder.decodeObject(forKey: "mentionID") as? String ?? ""
        type = MessageType(rawValue: coder.decodeObject(forKey: "type") as? String ?? "") ?? .undefined
        status = NewMessage.MessageStatusType(rawValue: coder.decodeInteger(forKey: "status")) ?? .read
        avatarURL = coder.decodeObject(forKey: "avatarURL") as? String
        name = coder.decodeObject(forKey: "name") as? String ?? ""
        createTime = coder.decodeDouble(forKey: "createTime")
        related = coder.decodeBool(forKey: "related")
        userID = coder.decodeObject(forKey: "userID") as? String ?? ""
        mentionString = coder.decodeObject(of: [NSAttributedString.self], forKey: "mentionString") as? NSAttributedString
        content = coder.decodeObject(forKey: "content") as? NSAttributedString
        tempContent = coder.decodeObject(forKey: "tempContent") as? String
        tempTransContent = coder.decodeObject(forKey: "tempTransContent") as? String
        commentCreateTime = coder.decodeDouble(forKey: "commentCreateTime")
        commentUpdateTime = coder.decodeDouble(forKey: "commentUpdateTime")
        quote = coder.decodeObject(forKey: "quote") as? String ?? ""
        isWhole = coder.decodeBool(forKey: "isWhole")
        finish = coder.decodeBool(forKey: "finish")
        modify = coder.decodeBool(forKey: "modify")
        translateContent = coder.decodeObject(of: [NSAttributedString.self], forKey: "translateContent") as? NSAttributedString
        localDelete = coder.decodeBool(forKey: "localDelete")
        translateStatus = CommentTranslateStatus(rawValue: coder.decodeObject(forKey: "translateStatus") as? String ?? "")
        countNumber = coder.decodeInteger(forKey: "countNumber")
        docType = DocsType(rawValue: coder.decodeInteger(forKey: "docType"))
        shouldShowCountNumber = coder.decodeBool(forKey: "shouldShowCountNumber")
        audioDuration = coder.decodeDouble(forKey: "audioDuration")
        audioFileToken = coder.decodeObject(forKey: "audioFileToken") as? String
        reactionType = coder.decodeObject(forKey: "reactionType") as? String
        isHandled = coder.decodeInteger(forKey: "isHandled")
        commentMention = coder.decodeInteger(forKey: "commentMention")
        commentDelete = coder.decodeInteger(forKey: "commentDelete")
        replyIndex = coder.decodeInteger(forKey: "replyIndex")
        subType = MessageSubType(rawValue: coder.decodeObject(forKey: "subType") as? String ?? "") ?? .normal
        likeCount = coder.decodeInteger(forKey: "likeCount")
        likeUsers = coder.decodeObject(forKey: "likeUsers") as? [String] ?? []
        emojiKey = coder.decodeObject(forKey: "emojiKey") as? String ?? ""
        
        func parsingAttrString(encodeString: String,
                               attributes: [NSAttributedString.Key: Any],
                               atInfoTransform: ((AtInfo) -> AtInfo)?) -> NSAttributedString {
            guard let xmlParser =  DocsContainer.shared.resolve(AtInfoXMLParserInterface.self) else {
                DocsLogger.error("xmlParser not found")
                return NSAttributedString()
            }
            return xmlParser.attrString(encodeString: encodeString, attributes: attributes, isHighlightSelf: true, useSelfCache: true, lineBreakMode: .byWordWrapping, permissionBlock: nil, userId: nil, selfNameMaxWidth: 0, atSelfYOffset: nil, atInfoTransform: atInfoTransform)
        }
        commentAttributedText = parsingAttrString(encodeString: tempContent ?? "", attributes: [.font: UIFont.systemFont(ofSize: 16)], atInfoTransform: nil).docs.urlAttributed
        quoteAttributedText = parsingAttrString(encodeString: quote, attributes: [.font: UIFont.systemFont(ofSize: 16)], atInfoTransform: nil)
                                                   .docs
                                                   .urlAttributed
    }

    public enum MessageType: String {
        case comment        = "MESSAGE_DOC_COMMENT" //评论
        case mention        = "MESSAGE_DOC_MENTION" //@
        case share          = "MESSAGE_DOC_SHARE"   //分享
        case card           = "MESSAGE_CARD"
        case undefined
    }

    public enum MessageStatusType: Int {
        case undefined = 0
        case unread = 1
        case read = 2
    }

    public enum MessageSubType: String {
        case reaction
        case commentSolve = "comment_solve"
        case like
        case commentReopen = "comment_reopen"
        case normal // 普通评论或者@
    }

    public var messageID = ""
    public var commentID = ""
    public var replyID   = ""
    public var mentionID = ""
    public var type: MessageType = .undefined
    public var status: NewMessage.MessageStatusType = .read
    public var avatarURL: String?
    public var name = ""
    public var createTime: TimeInterval = 0.0
    public var related: Bool = false
    public var userID: String = ""
    public var mentionString: NSAttributedString?

    public var content: NSAttributedString?
    public var commentCreateTime: TimeInterval = 0.0
    public var commentUpdateTime: TimeInterval = 0.0
    public var quote: String = ""
    public var isWhole: Bool = false
    public var finish: Bool = false
    public var modify: Bool = false
    public var translateStatus: CommentTranslateStatus?
    public var translateContent: NSAttributedString?
    public var localDelete: Bool = false
    public var isHandled: Int = 0 //是否处理过。 已经废弃，前端不返回
    public var commentDelete: Int = 0 //是否被删除
    public var commentMention: Int = 0 //是否有@本人
    public var replyIndex: Int = 0 //回复的index

    public var countNumber: Int = 0
    public var docType: DocsType = .doc
    public var shouldShowTranslatedComment: Bool = false
    public var shouldShowCountNumber: Bool = false

    public var audioDuration: TimeInterval = 0.0
    public var audioFileToken: String?
    public var reactions: [CommentReaction]?
    public var reactionType: String?
    public var tempContent: String?
    public var tempTransContent: String?
    public var tempContentV2: String? // 这里支持了点赞、reaction等新类型

    // 3.25新增了几种bot类型
    public var subType: MessageSubType = .normal
    public var likeCount: Int = 0
    public var likeUsers: [String] = []
    public var emojiKey: String = ""

    /// 正文表情回应的表情标识符(例如`Get`)，用于显示表情符号
    public private(set) var contentReactionKey = ""
    /// 正文表情回应：是否被取消
    public private(set) var contentReactionDelete = false
    
    // 根据content初始化的富文本
    var commentAttributedText: NSAttributedString?
    // 根据quote初始化的富文本
    var quoteAttributedText: NSAttributedString?
    
    var rawData: [String: Any]?
    
    public static func deserializeMessages(_ json: JSON) -> [NewMessage] {
        if json["data"]["messages"].arrayValue.count > 0 {
            return json["data"]["messages"].arrayValue.map { (json) -> NewMessage in
                return NewMessage.deserialize(json)
            }
        } else if json["data"]["message"].arrayValue.count > 0 {
            return json["data"]["message"].arrayValue.map { (json) -> NewMessage in
                return NewMessage.deserialize(json)
            }
        } else {
            return []
        }
    }

    public static func serializeMessages(_ msgs: [NewMessage]) -> [[String: Any]] {
        var messages: [[String: Any]] = []
        msgs.forEach { (msg) in
            let message = NewMessage.serialize(msg)
            messages.append(message)
        }
        return messages
    }

    public static func deserialize(_ json: JSON) -> NewMessage {
        let msg = NewMessage()
        msg.rawData = json.dictionaryObject
        if let mid = json["messageId"].string {
            msg.messageID = mid
        } else if let mid = json["message_id"].string {
            msg.messageID = mid
        }
        if let cid = json["commentId"].string {
            msg.commentID = cid
        } else if let cid = json["comment_id"].string {
            msg.commentID = cid
        }
        if let meid = json["mentionId"].string {
            msg.mentionID = meid
        } else if let meid = json["mention_id"].string {
            msg.mentionID = meid
        }
        if let rid = json["replyId"].string {
            msg.replyID = rid
        } else if let rid = json["reply_id"].string {
            msg.replyID = rid
        }
        msg.type = MessageType(rawValue: json["type"].stringValue) ?? .undefined
        msg.status = MessageStatusType(rawValue: json["status"].intValue) ?? .undefined
        if let au = json["avatarUrl"].string {
            msg.avatarURL = au
        } else if let au = json["avatar_url"].string {
            msg.avatarURL = au
        }
        msg.name = json["name"].stringValue
        if let ct = json["createTime"].double {
            msg.createTime = ct
        } else if let ct = json["create_time"].double {
            msg.createTime = ct
        }
        msg.isWhole = json["isWhole"].boolValue
        msg.related = json["related"].boolValue
        msg.userID = json["userId"].stringValue
        msg.localDelete = json["localDeleted"].boolValue
        if let value = json["contentReactionKey"].string {
            msg.contentReactionKey = value
        } else if let value = json["content_reaction_key"].string {
            msg.contentReactionKey = value
        }
        if let value = json["contentReactionDelete"].bool {
            msg.contentReactionDelete = value
        } else if let value = json["content_reaction_delete"].bool {
            msg.contentReactionDelete = value
        }
        msg.quote = json["quote"].stringValue
        msg.finish = json["finish"].boolValue
        if let cct = json["commentCreateTime"].double {
            msg.commentCreateTime = cct
        } else if let cct = json["comment_create_time"].double {
            msg.commentCreateTime = cct
        }
        msg.commentUpdateTime = json["commentUpdateTime"].doubleValue
        msg.mentionString = AtInfo.mentionString(userName: msg.name)
        msg.audioDuration = json["extra"]["attachment"]["audio_duration"].doubleValue
        msg.audioFileToken = json["extra"]["attachment"]["audio_file_token"].string
        msg.reactionType = json["reactionType"].string
        if let ss = json["solveStatus"].int {
            msg.isHandled = ss
        } else if let ss = json["solve_status"].int {
            msg.isHandled = ss
        }
        msg.commentDelete = json["commentDelete"].intValue
        msg.commentMention = json["commentMention"].intValue
        msg.replyIndex = json["replyIndex"].intValue

        // 3.25新增
        if let st = json["sub_type"].string {
            msg.subType = MessageSubType(rawValue: st) ?? .normal
        } else if let st = json["subType"].string {
            msg.subType = MessageSubType(rawValue: st) ?? .normal
        }

        if msg.subType == .reaction || msg.subType == .commentReopen {
            if let dataFromString = json["content"].rawString()?.data(using: .utf8, allowLossyConversion: false) {
                if let content = try? JSON(data: dataFromString) {
                    switch DocsSDK.currentLanguage {
                    // 我们的后台是一个神奇的后台，累了
                    case .ja_JP:
                        msg.content = NSAttributedString(string: content["content"]["content"].arrayValue.first?.arrayValue.first?["i18n"]["ja_jp"].string ?? "")
                        msg.quote = content["content"]["content"].arrayValue.last?.arrayValue.first?["i18n"]["ja_jp"].string?.parseHTMLConvertChar() ?? ""
                    case .zh_CN:
                        msg.content = NSAttributedString(string: content["content"]["content"].arrayValue.first?.arrayValue.first?["i18n"]["zh_cn"].string ?? "")
                        msg.quote = content["content"]["content"].arrayValue.last?.arrayValue.first?["i18n"]["zh_cn"].string?.parseHTMLConvertChar() ?? ""
                    case .en_US:
                        msg.content = NSAttributedString(string: content["content"]["content"].arrayValue.first?.arrayValue.first?["i18n"]["en_us"].string ?? "")
                        msg.quote = content["content"]["content"].arrayValue.last?.arrayValue.first?["i18n"]["en_us"].string?.parseHTMLConvertChar() ?? ""
                    default:
                        msg.content = NSAttributedString(string: content["content"]["content"].arrayValue.first?.arrayValue.first?["i18n"]["en_us"].string ?? "")
                        msg.quote = content["content"]["content"].arrayValue.last?.arrayValue.first?["i18n"]["en_us"].string?.parseHTMLConvertChar() ?? ""
                    }
                    if msg.subType == .reaction {
                        msg.emojiKey = content["content"]["content"].arrayValue.first?.arrayValue.last?["text"].string ?? ""
                    }
                    msg.tempContent = msg.content?.string
                }
            }

        } else if msg.subType == .like || msg.subType == .commentSolve {
            if let dataFromString = json["content"].rawString()?.data(using: .utf8, allowLossyConversion: false) {
                if let content = try? JSON(data: dataFromString) {
                    switch DocsSDK.currentLanguage {
                    case .ja_JP:
                        msg.content = NSAttributedString(string: content["content"]["content"].arrayValue.first?.arrayValue.first?["i18n"]["ja_jp"].string ?? "")
                    case .zh_CN:
                        msg.content = NSAttributedString(string: content["content"]["content"].arrayValue.first?.arrayValue.first?["i18n"]["zh_cn"].string ?? "")
                    default:
                        msg.content = NSAttributedString(string: content["content"]["content"].arrayValue.first?.arrayValue.first?["i18n"]["en_us"].string ?? "")
                    }
                    msg.tempContent = msg.content?.string

                    if msg.subType == .like {
                        msg.likeCount = content["content"]["content"].arrayValue.last?.arrayValue.first?["text"].intValue ?? 0
                        let likeUsersString: Data? = content["content"]["content"].arrayValue[1].arrayValue.first?["text"].rawString()?.data(using: .utf8)
                        if let lus = likeUsersString,
                            let likeUsers = try? JSON(data: lus) {
                            msg.likeUsers = likeUsers.arrayValue.map({ (avatar) -> String in
                                return avatar.stringValue
                            })
                        }
                    }

                }
            }
        }
        return msg
    }

    public static func serialize(_ msg: NewMessage) -> [String: Any] {
        if msg.rawData != nil {
            return msg.rawData ?? [:]
        }
        var json: [String: Any] = [:]
        json["messageId"] = msg.messageID
        json["commentId"] = msg.commentID
        json["mentionId"] = msg.mentionID
        json["replyId"] = msg.replyID
        json["type"] = msg.type.rawValue
        json["status"] = msg.status.rawValue
        json["name"] = msg.name
        json["createTime"] = msg.createTime
        json["isWhole"] = msg.isWhole == true ? 1 : 0
        json["avatarUrl"] = msg.avatarURL
        json["releated"] = msg.related
        json["userId"] = msg.userID
        json["localDeleted"] = msg.localDelete
        json["contentReactionKey"] = msg.contentReactionKey
        json["contentReactionDelete"] = msg.contentReactionDelete ? 1 : 0
        json["quote"] = msg.quote
        json["finish"] = msg.finish == true ? 1 : 0
        json["modify"] = msg.modify == true ? 1 : 0
        json["commentCreateTime"] = msg.commentCreateTime
        json["commentUpdateTime"] = msg.commentCreateTime
        if msg.subType != .normal {
            json["content"] = msg.tempContentV2
        } else {
            json["content"] = msg.tempContent
        }
        json["translateContent"] = msg.tempTransContent
        json["translateStatus"] = msg.translateStatus?.rawValue
        json["reactionType"] = msg.reactionType
        var extra: [String: Any] = [:]
        var attachment: [String: Any] = [:]
        attachment["audio_duration"] = msg.audioDuration
        attachment["audio_file_token"] = msg.audioFileToken
        extra["attachment"] = attachment
        json["extra"] = extra
        json["solveStatus"] = msg.isHandled
        json["commentDelete"] = msg.commentDelete
        json["commentMention"] = msg.commentMention
        json["replyIndex"] = msg.replyIndex

        json["subType"] = msg.subType.rawValue
        json["likeCount"] = msg.likeCount

        var reactions: [[String: Any]] = []

        msg.reactions?.forEach({ (reaction) in
            let reactionData = try? JSONEncoder().encode(reaction)
            guard let jsonDic = reactionData?.jsonDictionary else { return }
            reactions.append(jsonDic)
        })
        json["reaction"] = reactions

        return json
    }
}
