//
//  FeedMessage.swift
//  SKCommon
//
//  Created by huayufan on 2021/5/13.
//  

import HandyJSON
import SKResource
import SKFoundation
import LarkLocalizations
import SpaceInterface

public protocol FeedMessageType {
    /// 评论没有被删除
    var isAlive: Bool { get }
}

public final class FeedMessageModel: NSObject, Codable {
    
    enum CodingKeys: String, CodingKey {
        case avatarUrl
        case commentCreateTime
        case commentId
        case messageId
        case mentionId
        case commentMention
        case commentUpdateTime
        case createTime
        case content
        case quote
        case finish
        case isWhole
        case commentDelete
        case name
        case displayName
        case replyId
        case replyIndex
        case solveStatus
        case status
        case type
        case userId
        case translateContent
        case translateStatus
        case translateLang
        case localDeleted
        case subType
        case extra
        case contentReactionKey // 兼容了 content_reaction_key
        case contentReactionDelete // 兼容了 content_reaction_delete
    }
    
    public enum MessageType: String, Codable {
        case comment        = "MESSAGE_DOC_COMMENT" //评论
        case mention        = "MESSAGE_DOC_MENTION" //@
        case share          = "MESSAGE_DOC_SHARE"   //分享
        case card           = "MESSAGE_CARD"
        case docsReaction   = "MESSAGE_DOC_CONTENT_REACTION" //正文表情回应
    }
    
    public enum ReadStatus: Int, Codable {
        case unread = 1
        case read = 2
    }
    
    public enum TranslateStatus: String, Codable {
        case error
        case loading
        case success
    }
    
    public enum SubType: String, Codable {
        case reaction
        case commentSolve = "comment_solve"
        case like
        case commentReopen = "comment_reopen"
        case normal // 普通评论或者@
        
        public init(from decoder: Decoder) throws {
               let container = try decoder.singleValueContainer()
               let rawValue = try container.decode(String.self)
               self = SubType(rawValue: rawValue) ?? .normal
        }
    }
    
    /// 头像链接
    public private(set) var avatarUrl: String = ""
    
    /// 评论创建时间
    public private(set) var commentCreateTime: TimeInterval = 0
    
    /// 评论ID
    public private(set) var commentId: String = ""
    
    /// 唯一标识
    public private(set) var messageId: String = ""
    
    /// 提及的唯一标识
    public private(set) var mentionId: String = ""
    
    /// 是否是评论中的提及
    public private(set) var commentMention: Bool = false
    
    public private(set) var commentUpdateTime: TimeInterval = 0
    
    public private(set) var createTime: TimeInterval = 0
    
    /// 评论内容
    public private(set) var content: String = ""
    
    /// 评论的引用信息
    public private(set) var quote: String = ""
    
    /// 评论是否已被解决
    public private(set) var finish: Bool = false
    
    /// 是否是全文评论
    public private(set) var isWhole: Bool = false
    
    /// 评论是否被删除
    public private(set) var commentDelete: Bool = false
    
    
    //// 操作者名字
    public private(set) var name: String = ""
    
    /// 别名结构化字段
    public private(set) var aliasInfo: UserAliasInfo?
    
    public private(set) var replyId: String = ""
    
    /// 回复的index
    /// 当replyIndex >==0 时人名显示 `xxx在文档中发表了一条评论`
    /// 当replyIndex > 0 时人名显示 `xxx 在文档中发表了一条回复`
    public private(set) var replyIndex: Int = 0
    
    /// 评论是否已解决
    public private(set) var solveStatus: Bool = false
    
    /// 消息读取状态
    public var status: ReadStatus = .unread
    
    /// 评论类型
    public var type: MessageType?
    
    public private(set) var userId: String = ""
    
    /// 翻译模式下的内容
    public private(set) var translateContent: String?
    
    /// 翻译状态
    public private(set) var translateStatus: TranslateStatus?
    
    /// 翻译模式下的翻译语言
    public private(set) var translateLang: String?
    
    public private(set) var localDeleted: Bool = false
    
    /// 和相关后台沟通， reaction、commentReopen、like等类型已不使用
    /// reaction类型可根据上面type字段判断即可
    public private(set) var subType: SubType = .normal
    
    public private(set) var extra: [String: Any] = [:]
    
    /// 正文表情回应的表情标识符(例如`Get`)，用于显示表情符号
    public private(set) var contentReactionKey = ""
    /// 正文表情回应：是否被取消
    public private(set) var contentReactionDelete = false
    
    // MARK: - 以下字段为自定义辅助字段
    
//    @NotCoded
    var contentAttiString: NSAttributedString?
    
//    @NotCoded
    var translateAttiString: NSAttributedString?
    
    var isInvisible: Bool { User.current.basicInfo?.userID == userId }
    var addImageContent = false
    
    var lang: LarkLocalizations.Lang {
        guard let transLan = self.translateLang else {
            return .en_US
        }
        switch transLan {
        case "zh":
            return .zh_CN
        case "en":
            return .en_US
        case "ja":
            return .ja_JP
        case "th":
            return .th_TH
        default:
            return .en_US
        }
    }
    
    /// 国际化后的操作者别名
    public var displayName: String {
        if let displayName = aliasInfo?.currentLanguageDisplayName {
            return displayName
        } else {
            return name
        }
    }
    
    func formatMessage() {
        guard addImageContent == false else {
            return
        }
        defer { self.addImageContent = true }
        
        // 前端传过来的是[[String: Any]], 后台接口返回的是[String]; 这里用[Any]兼容两种情况
        var images = extra["image_list"] as? [Any] ?? []
        if images.isEmpty {
            images = extra["imageList"] as? [Any] ?? []
        }
        // 替换图片
        if !images.isEmpty {
            let imageString = images.reduce("") { res, _ in
                return res + "[\(BundleI18n.SKResource.Doc_Document_ExportImage)]"
            }
            if !self.content.isEmpty {
                self.content += "\n"
            }
            self.content += "\(imageString)"
            
            if let translateContent = self.translateContent,
               !translateContent.isEmpty {
                
                let imageStr = BundleI18n.SKResource.Doc_Document_ExportImage(lang: self.lang)
                let translateImageString = images.reduce("") { res, _ in
                    return res + "[\(imageStr)]"
                }
                self.translateContent = translateContent + "\n\(translateImageString)"
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
    }
    
    // MARK: - Codable
    // 手动解析，确保后台/前端某个字段返回格式有问题时不会解析失败
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        avatarUrl = (try? container.decodeIfPresent(String.self, forKey: .avatarUrl)) ?? ""
        commentCreateTime = (try? container.decodeIfPresent(TimeInterval.self, forKey: .commentCreateTime)) ?? 0
        commentId = (try? container.decodeIfPresent(String.self, forKey: .commentId)) ?? ""
        messageId = (try? container.decodeIfPresent(String.self, forKey: .messageId)) ?? ""
        mentionId = (try? container.decodeIfPresent(String.self, forKey: .mentionId)) ?? ""
        commentMention = (try? container.decodeIfPresent(Int.self, forKey: .commentMention)) == 1
        commentUpdateTime = (try? container.decodeIfPresent(TimeInterval.self, forKey: .commentUpdateTime)) ?? 0
        createTime = (try? container.decodeIfPresent(TimeInterval.self, forKey: .createTime)) ?? 0
        content = (try? container.decodeIfPresent(String.self, forKey: .content)) ?? ""
        quote = (try? container.decodeIfPresent(String.self, forKey: .quote)) ?? ""
        finish = (try? container.decodeIfPresent(Int.self, forKey: .finish)) == 1
        isWhole = (try? container.decodeIfPresent(Int.self, forKey: .isWhole)) == 1
        commentDelete = (try? container.decodeIfPresent(Int.self, forKey: .commentDelete)) == 1
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? ""
        aliasInfo = (try? container.decodeIfPresent(UserAliasInfo.self, forKey: .displayName))
        replyId = (try? container.decodeIfPresent(String.self, forKey: .replyId)) ?? ""
        replyIndex = (try? container.decodeIfPresent(Int.self, forKey: .replyIndex)) ?? 0
        solveStatus = (try? container.decodeIfPresent(Int.self, forKey: .solveStatus)) == 1
        status = (try? container.decodeIfPresent(ReadStatus.self, forKey: .status)) ?? .read
        type = (try? container.decodeIfPresent(MessageType.self, forKey: .type))
        userId = (try? container.decodeIfPresent(String.self, forKey: .userId)) ?? ""
        translateContent = (try? container.decodeIfPresent(String.self, forKey: .translateContent))
        translateStatus = (try? container.decodeIfPresent(TranslateStatus.self, forKey: .translateStatus))
        translateLang = (try? container.decodeIfPresent(String.self, forKey: .translateLang)) ?? ""
        localDeleted = (try? container.decodeIfPresent(Int.self, forKey: .localDeleted)) == 1
        subType = (try? container.decodeIfPresent(SubType.self, forKey: .subType)) ?? .normal
        extra = (try? container.decodeIfPresent([String: Any].self, forKey: .extra)) ?? [:]
        if let string = try? container.decodeIfPresent(String.self, forKey: .contentReactionKey) {
            contentReactionKey = string
        }
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: .contentReactionDelete) {
            contentReactionDelete = (intValue == 1)
        }
        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: .contentReactionDelete) {
            contentReactionDelete = boolValue
        }
        if let strValue = try? container.decodeIfPresent(String.self, forKey: .contentReactionDelete) {
            contentReactionDelete = (strValue == true.description)
        }
    }
    
    
    // MARK: - NSCoding
    required public init?(coder: NSCoder) {
        avatarUrl = coder.decodeObject(forKey: "avatarUrl") as? String ?? ""
        commentCreateTime = coder.decodeDouble(forKey: "commentCreateTime")
        commentId = coder.decodeObject(forKey: "commentId") as? String ?? ""
        messageId = coder.decodeObject(forKey: "messageId") as? String ?? ""
        mentionId = coder.decodeObject(forKey: "mentionId") as? String ?? ""
        commentMention = coder.decodeBool(forKey: "commentMention")
        commentUpdateTime = coder.decodeDouble(forKey: "commentUpdateTime")
        createTime = coder.decodeDouble(forKey: "createTime")
        content = coder.decodeObject(forKey: "content") as? String ?? ""
        quote = coder.decodeObject(forKey: "quote") as? String ?? ""
        finish = coder.decodeBool(forKey: "finish")
        isWhole = coder.decodeBool(forKey: "isWhole")
        commentDelete = coder.decodeBool(forKey: "commentDelete")
        name = coder.decodeObject(forKey: "name") as? String ?? ""
        if let aliasInfoProxy = coder.decodeObject(forKey: "displayName") as? UserAliasInfo.CodingProxy {
            aliasInfo = aliasInfoProxy.info
        }
        let reply_id_1 = coder.decodeObject(forKey: "reply_id") as? String ?? ""
        let reply_id_2 = coder.decodeObject(forKey: "replyId") as? String ?? ""
        if reply_id_1.isEmpty == false {
            replyId = reply_id_1
        } else if reply_id_2.isEmpty == false {
            replyId = reply_id_2
        } else {
            DocsLogger.feedError("replyId is Empty at `init?(coder: NSCoder)`, \(reply_id_1), \(reply_id_2)")
        }
        replyIndex = coder.decodeInteger(forKey: "replyIndex") as? Int ?? 0
        solveStatus = coder.decodeBool(forKey: "solveStatus")
        let st = coder.decodeInteger(forKey: "status") as? Int ?? 0
        status = ReadStatus(rawValue: st) ?? .read
        let ty = coder.decodeObject(forKey: "type") as? String ?? ""
        type = MessageType(rawValue: ty)
        userId = coder.decodeObject(forKey: "userId") as? String ?? ""
        translateContent = coder.decodeObject(forKey: "translateContent") as? String
        let sst = coder.decodeObject(forKey: "translateStatus") as? String ?? ""
        translateStatus = TranslateStatus(rawValue: sst)
        translateLang = coder.decodeObject(forKey: "translateLang") as? String ?? ""
        localDeleted = coder.decodeBool(forKey: "localDeleted")
        contentReactionKey = (coder.decodeObject(forKey: "contentReactionKey") as? String) ?? ""
        contentReactionDelete = coder.decodeBool(forKey: "contentReactionDelete")
        let stype = coder.decodeObject(forKey: "subType") as? String ?? ""
        subType = SubType(rawValue: stype) ?? .normal
    }
}


extension FeedMessageModel: FeedMessageType {
    
    public var isAlive: Bool {
        return !self.finish && !self.commentDelete
    }
}

extension FeedMessageModel {
    
    private static var associatedDocsTypeKey = UInt8(0)
    
    /// 所在文档的DocsType
    public var associatedDocsType: DocsType {
        get {
            if let value = objc_getAssociatedObject(self, &Self.associatedDocsTypeKey) as? Int {
                return DocsType(rawValue: value)
            }
            return DocsType.unknownDefaultType
        }
        set {
            let intValue = newValue.rawValue
            objc_setAssociatedObject(self, &Self.associatedDocsTypeKey, intValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
