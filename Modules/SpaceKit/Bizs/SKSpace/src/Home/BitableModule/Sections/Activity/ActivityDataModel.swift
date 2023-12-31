//
//  ActivityDataModel.swift
//  SKSpace
//
//  Created by yinyuan on 2023/4/17.
//

import Foundation
import SKFoundation
import SwiftyJSON
import SKCommon
import LarkLocalizations
import LarkStorage
import LarkAccountInterface
import BootManager
import SKResource
import SKInfra
import LarkSetting
import SpaceInterface

// 协议设计：https://bytedance.feishu.cn/docx/NHEzdlYcHo9BHcx9Bt9cCp2jnh3
// 协议设计：https://bytedance.feishu.cn/wiki/LEKuwFDO9iJ4vZkHRXecOVuBnDc

public struct HomePageData: Decodable {
    public let messageType: HomePageData.MessageType
    public let noticeInfo: HomePageData.NoticeInfo?
    public let cardInfo: HomePageData.CardInfo?
    public let teamMessage: HomePageData.TeamMessage?   // 端上硬编码插入的消息
    
    /// 埋点字段
    public var tarckTypeStr: String? {
        get {
            if messageType == .card {
                return "automation"
            } else if messageType == .notice {
                if noticeInfo?.noticeType == .BEAR_MENTION_AT_IN_CONTENT {
                    return "mention"
                }
                return "comment"
            }
            return nil
        }
    }
    
    public class NoticeInfo: Decodable {
        public let noticeID: String?
        public let sourceToken: String?
        public let fromUser: NoticeInfo.UserInfo?
        public let noticeTime: Int64?
        public let content: String?
        public let noticeType: NoticeInfo.NoticeType?
        public let objName: String?
        public let objUrl: String?
        public let noticeStatus: NoticeInfo.NoticeStatus?
        public let extra: String?
        
        /// 解析后的 content
        public lazy var contentModel: NoticeInfo.Content? = {
            do {
                let currentLang = LanguageManager.currentLanguage.rawValue.localizedLowercase
                let content = content?.replace(with: "_current_lang", for: "_\(currentLang)")
                if let data = content?.data(using: .utf8) {
                    return try JSONDecoder().decode(HomePageData.NoticeInfo.Content.self, from: data)
                }
            } catch {
                DocsLogger.error("parse content failed", error: error)
            }
            return nil
        }()
        
        /// 解析后的 content
        public lazy var extraModel: NoticeInfo.Extra? = {
            do {
                if let data = extra?.data(using: .utf8) {
                    return try JSONDecoder().decode(HomePageData.NoticeInfo.Extra.self, from: data)
                }
            } catch {
                DocsLogger.error("parse extra failed", error: error)
            }
            return nil
        }()
        
        /// 跳转 URL
        public lazy var linkURL: URL? = {
            guard let objUrl = objUrl, let url = URL(string: objUrl) else {
                return nil
            }
            var parameters: [String: String] = [:]
            if let comment_id = contentModel?.comment_id {
                parameters["comment_id"] = comment_id
            }
            if let reply_id = contentModel?.reply_id {
                parameters["reply_id"] = reply_id
            }
            if let table = extraModel?.notify_extra?.table {
                parameters["table"] = table
            }
            if let view = extraModel?.notify_extra?.view {
                parameters["view"] = view
            }
            return url.docs.addOrChangeEncodeQuery(parameters: parameters)
        }()
        
        public lazy var docName: String = {
            if let objName = objName, !objName.isEmpty {
                return objName
            }
            return DocsType.bitable.untitledString
        }()
        
        public class Content: Decodable {
            public let comment_content_for_feed: String?
            public let comment_content_for_feed_current_lang: String?
            public let comment_id: String?
            public let comment_owner_id: String?
            public let comment_owner_name: String?
            public let comment_owner_name_current_lang: String?
            public let operator_id: String?
            public let operator_name: String?
            public let operator_name_current_lang: String?
            public let pictures: String?
            public let pictures_current_lang: String?
            public let url_comment_owner_name: String?
            public let url_comment_owner_name_current_lang: String?
            public let url_operator_name: String?
            public let url_operator_name_current_lang: String?
            public let reaction_key: String?
            public let reaction_id: String?
            public let reply_id: String?
            
            /// 国际化处理后的 content
            public lazy var commentContentForFeedI18n: String? = {
                return comment_content_for_feed_current_lang ?? comment_content_for_feed
            }()
            
            /// 国际化处理后的 owner name
            public lazy var commentOwnerNameI18n: String? = {
                return comment_owner_name_current_lang ?? comment_owner_name
            }()
            
            /// 国际化处理后的 pictures
            public lazy var picturesI18n: String? = {
                return pictures_current_lang ?? pictures
            }()
        }
        
        public class Extra: Decodable {
            public let notify_extra: NotifyExtra?
            
            public class NotifyExtra: Decodable {
                public let table: String?
                public let view: String?
                public let record: String?
            }
        }
        
        public class UserInfo: Decodable {
            public let userID: String?
            public let avatarKey: String?
            public let name: String?
            public let enName: String?
            public let avatarUrl: String?
            public let userType: Int?
            public let displayName: String?
            
            public lazy var nameI18n: String? = {
                if let displayName = displayName {
                    return displayName
                }
                return LanguageManager.currentLanguage == .en_US ? enName : name
            }()
        }
        
        public enum NoticeStatus: Int, Decodable {
            case NORMAL = 0                                  // 正常
            case COMMENT_DELETE = 11                         // 评论被删除
            case COMMENT_FINISH = 12                         // 评论被解决
            case COMMENT_REACTION_FINISH = 13                // reaction对应的评论被解决
            case WHOLE_COMMENT_FINISH = 14                   // 全文评论被解决
            case FINISH_TO_REOPEN = 15                       // 评论解决后重新打开
            case REOPEN_TO_FINISH = 16                       // 评论打开后重新解决
            case  CONTENT_REACTION_FINISH = 17                // 正文Reaction被解决
            case CONTENT_REACTION_FINISH_TO_REOPEN = 18      // 解决的正文Reaction被重新打开
            case  CONTENT_REACTION_REOPEN_TO_FINISH = 19      // 重新打开的正文Reaction被解决
            case COMMENT_REACTION_DELETE = 21                // 评论reaction取消
            case CONTENT_REACTION_DELETE = 22                // 正文Reaction被撤销
            case PERMISSION_APPROVED = 31                    // 权限申请通过
            case PERMISSION_REJECTED = 32                    // 权限申请不通过
        }

        public enum NoticeType: Int, Decodable {
            case BEAR_COMMNET_ADD_COMMENT = 1 // 添加评论
            case BEAR_COMMNET_ADD_REPLY_NOTIFY_UPSTAIRS = 3// 添加回复
            case BEAR_COMMNET_FINISH_COMMENT = 4 // 解决评论
            case BEAR_COMMNET_REOPEN_COMMENT = 5 // 重新打开评论
            case BEAR_MENTION_AT_IN_CONTENT = 2001 //正文mention（提及了你）
            case BEAR_COMMENT_ADD_REACTION = 6  // 评论reaction
//            case BEAR_REACTION_ADD_CONTENT_REACTION = 8 // 添加正文reaction (目前没支持）
        }
    }

    public class CardInfo: Decodable {
        public let chatID: String?
        public let position: Int?
        public let noticeTime: Int64?
        public let content: String?
        public let sender: CardInfo.Sender?
        
        public struct Sender: Decodable {
            public let avatarKey: String?
            public let name: String?
            public let senderType: String?
        }
        
        public struct Content: Decodable {
            public let title: String?
        }
        
        /// 解析后的 content
        public lazy var contentModel: CardInfo.Content? = {
            do {
                if let data = content?.data(using: .utf8) {
                    return try JSONDecoder().decode(HomePageData.CardInfo.Content.self, from: data)
                }
            } catch {
                
            }
            return nil
        }()
        
        /// 卡片跳转链接
        public lazy var linkURL: URL? = {
            if let chatID = chatID, let position = position {
                var urlComponents = URLComponents(string: "lark://applink/client/chat/open")
                var queryItems = urlComponents?.queryItems ?? []
                queryItems.append(.init(name: "chatId", value: chatID))
                queryItems.append(.init(name: "position", value: String(position)))
                urlComponents?.queryItems = queryItems
                return urlComponents?.url
            }
            return nil
        }()
    }
    
    public struct TeamMessage: Decodable {
        public let content: String
    }

    public enum MessageType: Int, Decodable {
        case card = 1
        case notice = 2
        case teamMessage = 999
    }
}

public struct HomePageResponseData: Decodable {
    public let homePageData: [HomePageData]?
}

public struct GetHomePageResponse: Decodable {
    public let code: Int
    public let msg: String?
    public let data: HomePageResponseData?
}

public struct BaseHomePage: Decodable {
    public let activityEmptyConfig: ActivityEmptyConfig?
}

public struct ActivityEmptyConfig: Decodable {
    public let title: String?
    public let desc: String?
    public let button: String?
    public let buttonUrl: String?
}

public protocol ActivityDataModelDelegate: AnyObject {
    func dataUpdate()
}

public final class ActivityDataModel {
    
    private static let domain = Domain.biz.ccm.child("bitable").child("activities")
    private static let bitableGetHomepageCache = "bitableGetHomepageCache"
    
    public weak var delegate: ActivityDataModelDelegate?
    
    private var timer: Timer?
    private var latestPullTime: TimeInterval = 0
    
    private lazy var store: KVStore = {
        return KVStores.udkv(space: .user(id: AccountServiceAdapter.shared.currentChatterId), domain: Self.domain)
    }()
    
    public var homePageData: [HomePageData] = []
    public var failed: Bool = false
    
    public var activityEmptyConfig: ActivityEmptyConfig?
    
    public init() {
        updateSettingsConfig()
        // 先读缓存
        if let data = store.data(forKey: Self.bitableGetHomepageCache) {
            DispatchQueue.global().async { [weak self] in
                self?.handleData(data: data)
            }
        }
        // 再异步拉取刷新
        pull()
    }
    
    // 主动拉取
    public func pull() {
        let nowTime = Date().timeIntervalSince1970
        guard nowTime - latestPullTime > 5 else {
            // 限制刷新频率
            DocsLogger.info("ActivityDataModel pull limit")
            return
        }
        updateSettingsConfig()
        DocsLogger.info("ActivityDataModel pull data")
        latestPullTime = nowTime
        
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.bitableGetHomepage, params: [:])
        request.set(method: .GET)
        request.makeSelfReferenced()
        request.start { [weak self] (json, err) in
            guard let self = self else {
                return
            }
            guard err == nil else {
                DocsLogger.error("bitableGetHomepage error", error: err)
                if self.homePageData.isEmpty {
                    self.failed = true
                    DispatchQueue.main.async {
                        self.delegate?.dataUpdate()
                    }
                }
                return
            }
            do {
                if let data = try json?.rawData() {
                    self.store.set(data, forKey: Self.bitableGetHomepageCache)
                    self.handleData(data: data)
                }
            } catch {
                DocsLogger.error("bitableGetHomepage parse data error", error: error)
            }
            if UserScopeNoChangeFG.YY.bitableActivityNewDisable, self.homePageData.isEmpty {
                self.failed = true
                DispatchQueue.main.async {
                    self.delegate?.dataUpdate()
                }
            }
        }
    }
    
    private func updateSettingsConfig() {
        guard !UserScopeNoChangeFG.YY.bitableActivityNewDisable else {
            return
        }
        do {
            let homepage = try SettingManager.shared.setting(with: BaseHomePage.self, key: UserSettingKey.make(userKeyLiteral: "ccm_base_homepage"))
            self.activityEmptyConfig = homepage.activityEmptyConfig
        } catch {
            DocsLogger.error("ccm_base_homepage get settings error", error: error)
        }
    }
    
    private func handleData(data: Data) {
        do {
            let response = try JSONDecoder().decode(GetHomePageResponse.self, from: data)
            var homePageData = response.data?.homePageData ?? []
            if UserScopeNoChangeFG.YY.bitableActivityNewDisable {
                // 注入兜底消息
                homePageData.append(.init(messageType: .teamMessage, noticeInfo: nil, cardInfo: nil, teamMessage: .init(content: BundleI18n.SKResource.Bitable_Workspace_BaseTeamGreeting_Description)))
            }
            self.failed = false
            self.homePageData = homePageData
            DispatchQueue.main.async {
                self.delegate?.dataUpdate()
            }
        } catch {
            DocsLogger.error("bitableGetHomepage parse data error", error: error)
        }
    }
    
    public func pause() {
        DocsLogger.info("ActivityDataModel pause")
        // 暂停轮询
        if timer != nil {
            timer?.invalidate()
            self.timer = nil
        }
    }
    
    public func resume() {
        DocsLogger.info("ActivityDataModel resume")
        // 从后台回前台时主动拉取
        pull()
        // 恢复轮询
        timer?.invalidate()
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "ccm_base_homepage"))
            if let activityFetchInterval = settings["activityFetchInterval"] as? Int64, activityFetchInterval > 1000 {
                DocsLogger.info("ActivityDataModel activityFetchInterval=\(activityFetchInterval)")
                timer = Timer.scheduledTimer(withTimeInterval: Double(activityFetchInterval) / 1000, repeats: true) { [weak self] _ in
                    self?.pull()
                }
            } else {
                DocsLogger.warning("ActivityDataModel activityFetchInterval invalid")
            }
        } catch {
            DocsLogger.error("ActivityDataModel parse ccm_base_homepage get settings error", error: error)
        }
        
    }
}
