//
//  DocsReadingInfoModel.swift
//  SKCommon
//
//  Created by huayufan on 2021/10/18.
//  


import SwiftyJSON
import SKFoundation
import SpaceInterface

public enum DocsReadingData {
    /// 文字字数信息
    case words(ReadingInfo?)
    /// drive基本信息
    case fileMeta(ReadingInfo?)
    /// 访问数据
    case details(DocsReadingInfoModel?)
}

public final class DocsReadingInfoModel: NSObject {
    public private(set) var createTimestamp: TimeInterval = 0
    /// 文档所有者 id
    public private(set) var ownerUserId: String = ""
    /// 点赞总数
    public private(set) var likeCount: Int = 0
    /// 阅读次数
    public private(set) var pv: Int = 0
    /// 阅读人数
    public private(set) var uv: Int = 0
    /// 评论总数，新增字段
    public private(set) var commentsCount: Int = 0
    /// 今日新增点赞数，新增字段
    public private(set) var likeCountToday: Int = 0
    /// 今日新增阅读次数，新增字段
    public private(set) var pvToday: Int = 0
    /// 今日新增阅读人数，新增字段
    public private(set) var uvToday: Int?
    /// 今日新增评论数，新增字段
    public private(set) var commentsCountToday: Int = 0

    /// 文档所有者相关信息
    public private(set) var user: DocsReadingUserModel?
    
    public init(params: [String: Any], ownerId: String) {
        let json = JSON(params)
        self.createTimestamp = json["create_timestamp"].doubleValue
        self.ownerUserId = json["owner_user_id"].stringValue
        self.likeCount = json["like_count"].intValue
        self.pv = json["pv"].intValue
        self.uv = json["uv"].intValue
        self.commentsCount = json["comments_count"].intValue
        self.likeCountToday = json["like_count_today"].intValue
        self.pvToday = json["pv_today"].intValue
        self.uvToday = json["uv_today"].intValue
        self.commentsCountToday = json["comments_count_today"].intValue
        self.user = DocsReadingUserModel(params: json["entities"].dictionaryObject, ownerId: ownerId)
    }
}

public final class DocsReadingUserModel: NSObject {
    public private(set) var avatarUrl: String = ""
    public private(set) var cnName: String = ""
    public private(set) var email: String = ""
    public private(set) var enName: String = ""
    public private(set) var id: String = ""
    public private(set) var mobile: String = ""
    public private(set) var name: String = ""
    public private(set) var suid: String = ""
    public private(set) var tenantId: String = ""
    public private(set) var tenantName: String = ""
    public private(set) var uid: String = ""
    public private(set) var userType: String = ""
    public private(set) var aliasInfo: UserAliasInfo?
    /// 国际化后的别名
    public var displayName: String {
        if let displayName = aliasInfo?.currentLanguageDisplayName {
            return displayName
        } else {
            return enName
        }
    }
    
    public init (params: [String: Any]?, ownerId: String) {
        guard let pa = params else { return }
        let json = JSON(pa)
        let user = json["users"][ownerId]
        self.avatarUrl = user["avatar_url"].stringValue
        self.cnName = user["cn_name"].stringValue
        self.email = user["email"].stringValue
        self.enName = user["en_name"].stringValue
        self.id = user["id"].stringValue
        self.mobile = user["mobile"].stringValue
        self.name = user["name"].stringValue
        self.suid = user["suid"].stringValue
        self.tenantId = user["tenant_id"].stringValue
        self.tenantName = user["tenant_name"].stringValue
        self.uid = user["uid"].stringValue
        self.userType = user["user_type"].stringValue
        self.aliasInfo = UserAliasInfo(json: user["display_name"])
        
        if self.name.trim().isEmpty {
            DocsLogger.error("docs deading user name isEmpty len:\(self.name.count)")
        }
    }
    
}
