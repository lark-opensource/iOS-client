//
//  AppReviewConfig.swift
//  TTMicroApp
//
//  Created by xiangyuanyuan on 2021/12/22.
//

import Foundation

/// 评分配置
public struct OPAppReviewConfig {
    public static let ConfigName = "op_appreview_config"
    public let appReviewAppid: String
    public let baseAppLink: String
    public let openToAll: Bool
    public let appWhiteList: [String]
    public let appBlackList: [String]
    public struct ConfigKey {
        static let appid = "appreview_appid"
        static let applink = "appreview_applink"
        static let openAll = "open_to_all"
        static let appWhiteList = "app_white_list"
        static let appBlackList = "app_black_list"
    }

    public init?(config: [String: Any]) {
        guard let applink = config[ConfigKey.applink] as? String, applink != "",
              let appid = config[ConfigKey.appid] as? String, appid != "" else {
            return nil
        }
        self.baseAppLink = applink
        self.appReviewAppid = appid
        if let applyAll = config[ConfigKey.openAll] as? Bool {
            self.openToAll = applyAll
        } else {
            self.openToAll = false
        }
        if let appWhiteList = config[ConfigKey.appWhiteList] as? [String] {
            self.appWhiteList = appWhiteList.filter({$0 != ""})
        } else {
            self.appWhiteList = []
        }
        if let appBlackList = config[ConfigKey.appBlackList] as? [String] {
            self.appBlackList = appBlackList.filter({$0 != ""})
        } else {
            self.appBlackList = []
        }
    }
}

/// 获取AppLink所需参数
public struct AppLinkParams {
    
    public let appId: String
    public let appIcon: String
    public let appName: String
    public let appType: AppReviewAppType
    public let appVersion: String?
    public let origSeneType: String?
    public let pagePath: String?
    public let fromType: AppReviewFromType
    public let trace: String
    
    public init(appId: String,
                appIcon: String,
                appName: String,
                appType: AppReviewAppType,
                appVersion: String?,
                origSeneType: String?,
                pagePath: String?,
                fromType: AppReviewFromType,
                trace: String
    ) {
        self.appId = appId
        self.appIcon = appIcon
        self.appName = appName
        self.appType = appType
        self.appVersion = appVersion
        self.origSeneType = origSeneType
        self.pagePath = pagePath
        self.fromType = fromType
        self.trace = trace
    }
}

public struct AppReviewInfo: Codable {
    public let score: Float
    public let isReviewed: Bool
    public let lastTestSyncTime: TimeInterval
    public init(score: Float, isReviewed: Bool, lastTestSyncTime: TimeInterval) {
        self.score = score
        self.isReviewed = isReviewed
        self.lastTestSyncTime = lastTestSyncTime
    }
}

/// 被评分应用的触发方式
public enum AppReviewFromType: String {
    case container
    case api
}

/// 被评分应用的触发方式
public enum AppReviewAppType: String {
    case gadget
    case webapp
    case bot
}
