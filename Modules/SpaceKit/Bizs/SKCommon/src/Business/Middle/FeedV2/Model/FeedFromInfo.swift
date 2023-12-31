//
//  FeedFromInfo.swift
//  SKCommon
//
//  Created by huayufan on 2021/6/16.
//  


import SwiftyJSON


public final class FeedFromInfo {
    
    public enum FeedType: String {
        case unknown = "0"
        case mention = "1"
        case comment = "2"
        case reply   = "3"
        case solve   = "4"
        case share   = "5"
        case reopen  = "6"

        func toTrackerType() -> String {
            switch self {
            case .unknown:
                return "unknown"
            case .mention:
                return "mention"
            case .comment:
                return "comment"
            case .reply:
                return "reply"
            case .solve:
                return "sovle"
            case .share:
                return "share"
            case .reopen:
                return "reopen"
            }
        }
    }
    
    public var isFromLarkFeed: Bool = false
    /// 是否是来自系统推送
    public var isFromPushNotification = false
    public var unreadCount: Int = 0
    public var messageType: FeedType = .unknown
    public var feedId = ""
    
    public init() {}
    
    public class func deserialize(_ context: [String: Any]) -> FeedFromInfo {
        let info = FeedFromInfo()
        let json = JSON(context)
        info.isFromLarkFeed = json["docs_entrance"].stringValue == "docs_feed"
        info.isFromPushNotification = json["is_from_pushnotification"].boolValue
        info.unreadCount = json["unread_count"].intValue
        info.messageType = FeedType(rawValue: json["doc_message_type"].stringValue) ?? .unknown
        info.feedId = json["feed_id"].stringValue
        info.timestamps[.larkFeed] = json["timestamp"].double
        return info
    }
    
    // 是否满足主动打开Feed的条件
    public var canShowFeedAtively: Bool {
        if  self.isFromLarkFeed,
            self.unreadCount > 0 {
            return true
        }
        if self.isFromPushNotification {
            return true
        }
        return false
    }
    
    public enum Stage: String {
        case larkFeed // lark Feed 入口
        case beforeEditorOpen // EditorManger open之前
        case makeEditorEnd // 返回editor节点
        case registerServices
        case controllerInit // vc初始化完成
        case openPanel // 打开Feed面板前
    }
    
    fileprivate var timestamps: [Stage: TimeInterval] = [:]
    
    public func record(_ stage: Stage) {
        if timestamps[stage] == nil { // 以第一次为准
            timestamps[stage] = Date().timeIntervalSince1970 * 1000
        }
    }
    
    public func getTimestamp(with stage: Stage) -> TimeInterval? {
        return timestamps[stage]
    }
    
    var entrance: Int {
        if isFromLarkFeed {
            return 1
        } else if isFromPushNotification {
            return 2
        } else { // 小铃铛
            return 0
        }
    }
}
