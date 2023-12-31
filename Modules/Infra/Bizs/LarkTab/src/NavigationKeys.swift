//
//  NavigationKeys.swift
//  LarkTab
//
//  Created by Supeng on 2020/12/16.
//

// swiftlint:disable identifier_name missing_docs
import Foundation

public enum NavigationKeys {
    public static let name = "name"
    public static let logo = "logo"
    public static let appid = "app_id"
    public static let mobileUrl = "mobile_url"
    public static let uniqueid = "unique_id"
    public static let launcherFrom = "launcher_from"
    public static let bizType = "biz_type"
    public static let tabBizId = "biz_id"
    public static let iconInfo = "iconInfo"
    public static let displayName = "displayName"
    
    /// 标记iPad上从edage打开的vc是在固定区，还是临时区
    public enum LauncherFrom {
        /// 固定区
        public static let main = "main"
        /// “更多”里打开
        public static let quick = "quick"
        /// 临时区
        public static let temporary = "temporary"
        /// 多任务浮窗
        public static let suspend = "suspend"
    }
    
    /// Tab localization name keys
    public enum Name {
        public static let ja_JP = "ja_jp"
        public static let en_US = "en_us"
        public static let zh_CN = "zh_cn"
    }
// swiftlint:enable identifier_name
    /// Tab logo config keys
    public enum Logo {
        /// main tab icon, 不支持染色的deault图片，后续逐渐下掉，新上传图片使用新字段，mobileDefaultIcon
        public static let mainDefault = "primary_default"

        /// main tab selected icon, 不支持染色的selected图片，后续逐渐下掉，新上传图片使用新字段，mobileSelectedIcon
        public static let mainSelected = "primary_selected"

        /// main tab support tintColor icon, 历史存量图片使用，后续逐渐下掉
        public static let mainSupportTintColor = "primary_tintcolor"
        
        /// main tab support tintColor default icon
        public static let mobileDefaultIcon = "mobile_primary_default_png"
        
        /// main tab selected icon
        public static let mobileSelectedIcon = "mobile_primary_selected_png"

        /// quick tab icon
        public static let quickDefault = "secretary_default"

        /// quick tab backgroundColor
        public static let quickBackgroundColor = "secretary_bgcolor"
    }
}

public extension Tab {
    /// 小程序、H5 appid
    var appid: String? {
        guard self.appType != .native else { return nil }
        return self.extra[NavigationKeys.appid] as? String
    }

    var logo: [String: String]? {
        return self.extra[NavigationKeys.logo] as? [String: String]
    }

    var mobileUrl: String? {
        return self.extra[NavigationKeys.mobileUrl] as? String
    }

    /// 仅为兼容旧数据，后续可逐渐下掉，使用新字段 mobileRemoteDefaultIcon
    var remoteIcon: String? {
        return self.logo?[NavigationKeys.Logo.mainDefault]
    }

    /// 仅为兼容旧数据，后续可逐渐下掉，使用新字段 mobileRemoteSelectedIcon
    var remoteSelectedIcon: String? {
        return self.logo?[NavigationKeys.Logo.mainSelected]
    }

    var remoteSupportTintColorIcon: String? {
        return self.logo?[NavigationKeys.Logo.mainSupportTintColor]
    }

    /// 支持染色
    var mobileRemoteDefaultIcon: String? {
        return self.logo?[NavigationKeys.Logo.mobileDefaultIcon]
    }

    /// 原图展示，不支持染色，可能是彩色
    var mobileRemoteSelectedIcon: String? {
        return self.logo?[NavigationKeys.Logo.mobileSelectedIcon]
    }

    var remoteQuickIcon: String? {
        return self.logo?[NavigationKeys.Logo.quickDefault]
    }

    var remoteQuickBackgroundeColor: String? {
        return self.logo?[NavigationKeys.Logo.quickBackgroundColor]
    }
}
// swiftlint:enable missing_docs
