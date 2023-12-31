//
//  OPShareBody.swift
//  LarkOPInterface
//
//  Created by bytedance on 2022/9/15.
//

import Foundation
import EENavigator
import LarkModel
import LarkShareContainer

/// 唤起三个tab的分享组件的 body
public struct OPShareBody: PlainBody {
    public static var pattern: String = "//client/open_platform/share"
    /// 分享类型
    public let shareType: ShareType
    /// 分享来源（用于埋点）, 未来会下掉
    public let from: String
    /// tracking
    public let opTracking: String
    /// 分享事件处理回调
    public let eventHandler: ShareEventHandler?

    public init(
        shareType: ShareType,
        from: String,
        opTracking: String,
        eventHandler: ShareEventHandler? = nil
    ) {
        self.shareType = shareType
        self.from = from
        self.opTracking = opTracking
        self.eventHandler = eventHandler
    }

    public init(
        shareType: ShareType,
        fromType: ShareFromType,
        eventHandler: ShareEventHandler? = nil
    ) {
        self.init(
            shareType: shareType,
            from: fromType.rawValue,
            opTracking: fromType.opTracking,
            eventHandler: eventHandler
        )
    }
}

/// 分享类型
public enum ShareType {
    /// 应用分享
    case app(ShareApp)

    /// 应用页面分享
    case appPage(ShareAppPage)

    /// h5 分享
     case h5(ShareH5Content)
}

/// 应用分享
public struct ShareApp {
    /// appId
    public var appId: String
    /// 分享链接，可选。不填则使用 /client/app_share/open 作为默认链接
    public var link: String?

    public init(appId: String, link: String? = nil) {
        self.appId = appId
        self.link = link
    }
}

public struct ShareH5Content {
    
    public var title: String?
    
    public var link: String

    public init(title: String? = nil, link: String) {
        self.title = title
        self.link = link
    }
}

/// 应用页面分享
public struct ShareAppPage {
    /// appId
    public var appId: String

    /// 自定义分享标题
    public var title: String

    /// 分享icon
    public var iconKey: String?

    /// 分享url
    public var url: String

    /// 分享applinkURL
    public var applinkHref: String?

    /// 分享options
    public var options: ShareOptions

    public init(
        appId: String,
        title: String,
        iconKey: String?,
        url: String,
        applinkHref: String?,
        options: ShareOptions
    ) {
        self.appId = appId
        self.title = title
        self.iconKey = iconKey
        self.url = url
        self.applinkHref = applinkHref
        self.options = options
    }
}

/// 分享事件处理
public struct ShareEventHandler {
    /// 分享完成 (data, isCancel)
    public var shareCompletion: (([String: Any]?, Bool) -> Void)?

    public init(shareCompletion: (([String: Any]?, Bool) -> Void)? = nil) {
        self.shareCompletion = shareCompletion
    }
}

/// 默认提供的分享入口类型枚举，也可自行根据业务定义
public enum ShareFromType: String {
    case profile            = "profile"             // 应用 profile 页分享入口点击
    case workplaceAppCard   = "workplace_appcard"   // 工作台应用卡片分享入口点击
    case gadgetPageShare    = "gadget_pageshare"    // 小程序页面分享入口点击
    case gadgetAbout        = "gadget_about"        // 小程序关于页分享入口点击
    case webAppAbout        = "web_app_about"       // 网页应用关于页分享入口点击
    case webAppPageShare    = "web_app_pageshare"   // 网页应用容器点击分享入口
    case webPageShare       = "web_pageshare"       // 普通h5网页的容器点击分享入口
    case ttqAPI             = "ttq_api"             // 头条圈特化分享
    case h5SDKAPI           = "h5_sdk_api"          // H5 SDK API 分享
    case shareH5API         = "share_h5_content_api"// 分享网页应用API

    /// tracking 用于追踪场景
    public var opTracking: String {
        return "opshare_\(rawValue)"
    }
}
