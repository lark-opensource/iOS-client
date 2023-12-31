//
//  LikeModels.swift
//  SpaceKit
//
//  Created by Webster on 2018/12/5.
//

import Foundation
import SwiftyJSON
import SpaceInterface

public final class LikeUserInfo: NSObject {
    public var likeId: String = "0"
    public var likeThisUserId: String = "0"
    public var name: String?
    public var avatarURL: String = ""
    public var updateTimestamp: TimeInterval?
    public var createTimestamp: TimeInterval?
    public var tenantId: String?
    /// 是否允许进入profile界面
    public var allowEnterProfile: Bool = false
    /// 国际化后的别名
    public var displayName: String?

    public var displayTag: DisplayTagInfo? // 关联标签

    public class func objByJson(json: JSON) -> LikeUserInfo {
        let obj = LikeUserInfo()
        obj.likeId = json["id"].stringValue
        obj.likeThisUserId = json["user_id"].stringValue
        obj.updateTimestamp = (json["update_time"].rawValue as? TimeInterval) ?? 0
        obj.createTimestamp = (json["create_time"].rawValue as? TimeInterval) ?? 0
        obj.tenantId = json["tenantId"].stringValue
        obj.allowEnterProfile = json["is_desensitize"].boolValue == false // is_desensitize为true，不能点击进入profile
        return obj
    }

    /// 新的信箱推送数据
    public class func objByMessageResponseJson(_ json: JSON) -> LikeUserInfo {
        /// 新的信箱推送数据有以下信息
        let obj = LikeUserInfo()
        let isEn = (DocsSDK.currentLanguage == .en_US)
        let localName = json["name"].stringValue
        let enName = json["en_name"].stringValue
        obj.name = isEn ? enName : localName
        obj.avatarURL = json["avatar_url"].stringValue
        obj.likeThisUserId = json["id"].stringValue
        obj.tenantId = json["tenant_id"].stringValue
        obj.allowEnterProfile = json["is_desensitize"].boolValue == false
        return obj
    }
}

public final class LikeUserDetails {
    public var name: String = ""
    public var userId: String = ""
    public var avatarUrl: String = ""
    public var tenantId: String = ""
    /// 是否允许进入profile界面
    public var allowEnterProfile: Bool = false
    /// 别名结构化字段
    public var aliasInfo: UserAliasInfo?
    /// 国际化后的别名
    public var displayName: String? {
        if let displayName = aliasInfo?.currentLanguageDisplayName {
            return displayName
        } else {
            return name
        }
    }
    public var displayTag: DisplayTagInfo? // 关联标签

    public class func objByJson(json: JSON) -> LikeUserDetails {
        let obj = LikeUserDetails()
        let isEn = (DocsSDK.currentLanguage == .en_US)
        let localName = json["name"].stringValue
        let enName = json["en_name"].stringValue
        obj.name = isEn ? enName : localName
        obj.aliasInfo = UserAliasInfo(json: json["display_name"])
        obj.userId = json["id"].stringValue
        obj.avatarUrl = json["avatar_url"].stringValue
        obj.tenantId = json["tenant_id"].stringValue
        obj.allowEnterProfile = json["is_desensitize"].boolValue == false
        
        if json["display_tag"] != nil, let tagValue = json["display_tag"] as? JSON {
            obj.displayTag = DisplayTagInfo(json: tagValue)
        }
        return obj
    }
}
