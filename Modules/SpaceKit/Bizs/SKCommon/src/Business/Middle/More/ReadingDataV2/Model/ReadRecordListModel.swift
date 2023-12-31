//
//  ReadRecordListModel.swift
//  SKCommon
//
//  Created by huayufan on 2021/10/21.
//  


import Foundation
import SKCommon
import SKFoundation
import SKResource
import LarkTimeFormatUtils
import SwiftyJSON
import SpaceInterface

public final class ReadRecordInfo: NSObject {
    // 总阅读人数
    public var uv: Int = 0
    // 隐身阅读人数
    public var hiddenUv: Int = 0
    public var readUsers: [ReadRecordUserInfoModel] = []
    public var nextPageToken: String = ""
    public init(uv: Int = 0,
                hiddenUv: Int = 0,
                readUsers: [ReadRecordUserInfoModel] = [],
                nextPageToken: String = "") {
        self.uv = uv
        self.hiddenUv = hiddenUv
        self.readUsers = readUsers
        self.nextPageToken = nextPageToken
    }

    public func reset() {
        uv = 0
        hiddenUv = 0
        nextPageToken = ""
        readUsers.removeAll()
    }
}

public final class ReadRecordUserInfoModel: NSObject {
    
    public enum UserType: Int {
        case normal = 1         // 普通用户
        case anonymous = 2      // 匿名用户
        case temporary = 3      // 临时用户
        case application = 4    // 应用用户
    }
    
    public var userID: String = ""
    public var name: String = ""
    public var enName: String = ""
    public var avatarURL: String = ""
    public var department: String = ""
    // 用户类型
    public var userType: UserType = .normal
    // 是否为外部租户
    public var isExternal: Bool = false
    // 是否离职
    public var isResigned: Bool = false
    // 最近阅读时间
    public var lastViewTimestamp: TimeInterval?
    // 允许进入用户资料界面
    public var canShowProfile: Bool = false
    
    public var timeText: String = ""
    
    public var aliasInfo: UserAliasInfo?
    /// 国际化后的别名
    public var displayName: String {
        if let displayName = aliasInfo?.currentLanguageDisplayName {
            return displayName
        } else {
            return enName
        }
    }

    // 显示关联标签
    public var displayTag: DisplayTagSimpleInfo?

    public init(userID: String = "",
                name: String = "",
                enName: String = "",
                avatarURL: String = "",
                department: String = "",
                userType: UserType = .normal,
                isExternal: Bool = false,
                isResigned: Bool = false,
                lastViewTimestamp: TimeInterval?,
                canShowProfile: Bool = false,
                aliasInfo: UserAliasInfo? = nil,
                displayTag: DisplayTagSimpleInfo?) {
        self.userID = userID
        self.name = name
        self.enName = enName
        self.avatarURL = avatarURL
        self.department = department
        self.userType = userType
        self.isExternal = isExternal
        self.isResigned = isResigned
        self.lastViewTimestamp = lastViewTimestamp
        self.canShowProfile = canShowProfile
        self.aliasInfo = aliasInfo
        self.displayTag = displayTag
    }
    
    static func convertReadUsersInfo(_ users: [[String: Any]]) -> [ReadRecordUserInfoModel] {
        var models = [ReadRecordUserInfoModel]()
        users.forEach { user in
            guard let userID = user["id"] as? String
            else {
                DocsLogger.info("阅读记录列表人员缺少id信息")
                return
            }
            let name = user["name"] as? String ?? ""
            let enName = user["en_name"] as? String ?? ""
            let avatarUrl = user["avatar_url"] as? String ?? ""
            let department = user["department"] as? String ?? ""
            let userType = user["user_type"] as? Int ?? 1
            let isExternal = user["is_external"] as? Bool ?? false
            let isResigned = user["is_resigned"] as? Bool ?? false
            let lastViewTime = user["last_view_time"] as? Double
            let showProfile = user["can_show_profile"] as? Bool ?? false
            let displayNameInfo = user["display_name"] as? [String: Any]
            var displayTag: DisplayTagSimpleInfo?
            if let tag = user["display_tag"] as? [String: Any] {
                displayTag = DisplayTagSimpleInfo(data: tag)
            }
            let userInfoModel = ReadRecordUserInfoModel(userID: userID,
                                                        name: name,
                                                        enName: enName,
                                                        avatarURL: avatarUrl,
                                                        department: department,
                                                        userType: UserType(rawValue: userType) ?? .normal,
                                                        isExternal: isExternal,
                                                        isResigned: isResigned,
                                                        lastViewTimestamp: lastViewTime,
                                                        canShowProfile: showProfile,
                                                        aliasInfo: displayNameInfo.map { UserAliasInfo(data: $0) },
                                                        displayTag: displayTag)
            models.append(userInfoModel)
        }
        return models
    }
}

extension ReadRecordUserInfoModel {
    
    var time: String {
        if timeText.isEmpty,
            let lastViewTimestamp = lastViewTimestamp {
            let commentDate: Date = Date(timeIntervalSince1970: lastViewTimestamp)
            let option = LarkTimeFormatUtils.Options(
                is12HourStyle: false,
                shouldShowGMT: false,
                timeFormatType: .short,
                dateStatusType: .relative
            )
            timeText = TimeFormatUtils.formatDate(from: commentDate, with: option)
        }
        return timeText
    }
    
    var descText: String {
        if userType == UserType.anonymous {
            return  BundleI18n.SKResource.CreationMobile_Stats_Visits_AnonVisitDesc
        }
        return department
    }
    
    var isShowExternal: Bool { // 显示"外部"标签
        return isExternal
    }
    
    /// 根据语言环境显示的名字
    var localizedName: String {
//        DocsSDK.currentLanguage == .zh_CN ? name : enName
        displayName
    }
}
