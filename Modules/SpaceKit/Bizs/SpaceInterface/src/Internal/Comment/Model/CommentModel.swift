//
//  NewCommentViewData.swift
//  SpaceKit
//
//  Created by bytedance on 2018/10/25.
//

import UIKit

public struct CommentPermission: OptionSet {
    public let rawValue: Int

    public static let canComment = CommentPermission(rawValue: 1 << 0) // 是否可以评论
    public static let canResolve = CommentPermission(rawValue: 1 << 1) // 是否可以解决
    public static let canShowMore = CommentPermission(rawValue: 1 << 2) // 是否展示更多按钮
    public static let canShowVoice = CommentPermission(rawValue: 1 << 3) // 是否展示语音评论
    public static let canReaction = CommentPermission(rawValue: 1 << 4) // 是否可以发出 Reaction
    public static let canReopen = CommentPermission(rawValue: 1 << 5) // 是否可以重新打开
    public static let canCopy = CommentPermission(rawValue: 1 << 6) // 是否可以复制
    public static let canNotDelete = CommentPermission(rawValue: 1 << 7) // 是否不可以删除, 删除逻辑比较特殊, 默认都是可以删除的, 只有 drive 的历史评论不支持删除
    public static let canTranslate = CommentPermission(rawValue: 1 << 8)
    public static let canDownload = CommentPermission(rawValue: 1 << 10) // 评论中的图片是否可下载
    public static let disableImgPreview = CommentPermission(rawValue: 1 << 11) // 禁止预览评论中的图片(CCM文档CAC管控时用到)

    // 自定义字段
    public static let disableAutoActiveKeyboard = CommentPermission(rawValue: 1 << 9)
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// 文档互动行为类型
public enum DocsInteractionType: Int {
    case comment = 0    // 文字评论
    case reaction = 1   // 正文表情回应
}

public final class Comment {
    public var commentID = ""
    public var commentUUID = ""
    public var finish: Int?
    public var quote: String?
    public var finishUserID: String?
    public var userId = "" // 卡片owner(该卡片上发表首条评论)的userID
    public var finishUserName: String?
    public var parentToken: String?
    public var parentType: String?
    public var isWhole = false
    public var commentList: [CommentItem] = []
    public var isUnsummit: Bool = false
    
    public var bizParams: [String: Any]?
    // 评论位置信息(区别于iPad 高度pos)
    public var position: String?
    
    public var isNewInput: Bool = false
    
    public var commentDocsInfo: CommentDocsInfo?
    /// 自定义字段
    public var isActive: Bool = false {
        didSet {
            commentList.forEach {
                $0.isActive = isActive
            }
        }
    }

    public var interactionType: DocsInteractionType?

    // 是否正在编辑/输入
    public var isFirstResponser: Bool = false

    public var permission: CommentPermission = []
    
    public init() { }
}

public enum CommentTranslateStatus: String {
    case error
    case loading
    case success
}

public enum CommentItemRetryType: String {
    case add
    case update
    case delete
    case reply
}

public final class CommentItem {
    
    public enum UIType {
        case normal_reply       // 文字回复
        case normal_reaction    // 表情回应
        case header
        case footer
        case unsupported
    }
    
    public enum CommentReadStatus: Int {
        case undefined = 0
        case unread = 1
        case read = 2
    }
    
    public enum ReplyType: Int {
        case content = 0
    }
    
    public enum ErrorCode: Int {
        case loadImageError = -1010
        case network = -8
        case permission = 4
        case violateTOS1 = 10009 // 当前评论不符合用户协议，请调整内容后重新发送
        case violateTOS2 = 10013 // 当前评论不符合用户协议，请调整内容后重新发送
        case mgError1 = 900004510 // 当前文档暂未开放评论
        case mgError2 = 900004511 // 当前文档暂未开放评论
        case preparingData = 900004230 // 数据准备中，暂时无法处理相关操作，请稍后重试
    }
    
    public var replyID: String = ""
    public var replyType: ReplyType?
    public var userID: String = ""
    public var content: String?
    public var creatTime: String?
    public var updateTime: String?
    public var name: String?
    public var avatarURL: String?
    public var createTimeStamp: TimeInterval?
    public var updateTimeStamp: TimeInterval?
    public var modify: Int?
    public var messageId: String = ""
    public var status: CommentReadStatus = .undefined
    public var previewImageInfos: [CommentImageInfo] {
        return imageList
    }

    public var commentId: String?

    public var audioDuration: TimeInterval?
    public var audioFileToken: String?

    public var reactions: [CommentReaction]?

    public var reactionType: String?

    // 翻译
    public var translateContent: String?
    public var translateStatus: CommentTranslateStatus?
    public var targetLanguage: String?
    public var contentSourceLanguage: String?
    public var userMainLanguage: String?
    public var defaultTargetLanguage: String?

    // 是否匿名
    public var anonymous: Bool = false

    public var isSending: Bool = false
    public var errorCode: Int = 0
    public var enumError: ErrorCode? {
        return ErrorCode(rawValue: errorCode)
    }
    public var errorMsg: String = ""
    public var retryType: CommentItemRetryType?
    // 回复/编辑评论时, 会传给前端一个唯一标识，这是前端回传过来的同一个标识，用于定位一条回复，上报成功率
    public var replyUUID = ""

    //评论图片
    public var imageList: [CommentImageInfo] = []
    
    public var uiType: UIType = .normal_reply
    /// 本地字段，注意与uiType要保持同步
    public var interactionType: DocsInteractionType?
    
    public var isNewInput: Bool = false
    
    public var attrCache: [String: NSAttributedString] = [:]
    
    /// 侧边栏评论（iPad）是否正在编辑或者回复
    public var isEditing: Bool = false
    
    public var commentDocsInfo: CommentDocsInfo?
    
    public var heightCacheKey: String {
        return replyID
    }
    
    public enum ViewStatus: Equatable {
      case normal // 普通的评论 or 表情回应
      case edit(isFirstResponser: Bool)  // 编辑状态下的评论
      case reply(isFirstResponser: Bool) // 新增/回复状态下的评论
      
        
       public var isEdit: Bool {
           if case .edit = self {
               return true
           } else {
               return false
           }
       }
        
        public  var isFirstResponser: Bool {
            switch self {
            case let .edit(isFirst),
                 let .reply(isFirst):
                return isFirst
            default:
                return false
            }
        }

        public mutating func resign() {
            updateFirstResponser(false)
        }
        
        public mutating func focus() {
            updateFirstResponser(true)
        }

        private mutating func updateFirstResponser(_ isActive: Bool) {
            switch self {
            case .edit:
                self = .edit(isFirstResponser: isActive)
            case .reply:
                self = .reply(isFirstResponser: isActive)
            default:
                break
            }
        }
    }
    
    public var viewStatus: ViewStatus = .normal

    public var permission: CommentPermission = []
    
    public var isActive = false
    
    public var quote: String?

    public init() {}
}

public struct CommentReaction: Codable {

    public enum UserDescriptionType: Int, Codable {
        case defaultType
        case business
        case leave
        case meeting
    }

    public struct UserInfo: Codable {
        // 个人信息
        public let avatarUrl: String
        public let userName: String
        public let userId: String
        public let anonymous: Bool?
        
        // 个人状态
        public let description: String?
        public let descType: UserDescriptionType?
        
        // (以下字段目前没有用上)
        public let workStatusDesc: String?
        public let isRegistered: Bool?
        public let avatarKey: String?
    }

    public let referType: String
    public let referKey: String?
    public let reactionKey: String
    public let totalCount: Int
    public let userList: [UserInfo]

    public var replyId: String?
    public var commentId: String? // 评论卡片id,仅用于正文reaction
}

public struct CommentStatsExtra: Codable {

    public enum From: String, Codable {
        case bubble
        case topBar
        case bubbleMenu = "bubble_menu"
        case blockMenu = "block_menu"
        case reactionMenu = "reaction_menu"
        case replyArea = "reply_area"
        case feed
        case autoUnfolding
        case imageComment = "image_comment"
    }
    
    public enum Action {
        case render
        case edit
    }

    /// 前端返回时间戳
    public var clickTime: TimeInterval?
    
    public var clickFrom: From?
    
    /// 端上收到前端数据的时间戳
    public var receiveTime: TimeInterval?
    
    public var recordedRender: Bool? = false
    public var recordedEdit: Bool? = false
    
    public var keepUtilEdit: Bool? = false
    
    public init(clickTime: TimeInterval? = nil, clickFrom: CommentStatsExtra.From? = nil, receiveTime: TimeInterval? = nil) {
        self.clickTime = clickTime
        self.clickFrom = clickFrom
        self.receiveTime = receiveTime
    }
    
    /// 标记不需要上报加载耗时
    public mutating func markRecordedRender() {
        recordedRender = true
    }
    
    /// 标记不需要上报编辑耗时
    public mutating func markRecordedEdit() {
        recordedEdit = true
    }
    
    public mutating func generateReceiveTime() {
        if receiveTime == 0 ||  receiveTime == nil {
            receiveTime = Date().timeIntervalSince1970 * 1000
        }
    }

    public mutating func updateUtilEdit(utilEdit: Bool) {
        self.keepUtilEdit = utilEdit
    }
    
    public func calculateDuration() -> (bridgeTime: TimeInterval, renderTime: TimeInterval, totalTime: TimeInterval)? {
        guard let receiveTime = self.receiveTime,
              let clickTime = self.clickTime else {
            return nil
        }
        let now = Date().timeIntervalSince1970 * 1000
        let renderTime = now - receiveTime
        let totalTime = now - clickTime
        let bridgeTime = receiveTime - clickTime
        return (bridgeTime, renderTime, totalTime)
    }
}

public struct CommentWrapper {
    public init(commentItem: CommentItem, comment: Comment) {
        self.commentItem = commentItem
        self.comment = comment
    }
    
    public var commentItem: CommentItem
    public var comment: Comment
    
}


extension Array where Element == CommentItem {
    
    // 过滤了header和footer数据源
    public var realCount: Int {
        let items = self.filter { $0.uiType.isNormal }
        return items.count
    }
}

extension CommentItem.UIType {
    public var isNormal: Bool {
        let abnormalList: [CommentItem.UIType] = [.header, .footer, .unsupported]
        return abnormalList.contains(self) == false
    }
}
