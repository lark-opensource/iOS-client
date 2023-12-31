//
//  ShareH5Service.swift
//
//  Created by Meng on 2020/12/7.
//

import Foundation
import LarkModel
//code from zhangmeng
/// 统一收敛的H5分享服务(LarkOPWeb容器/LarkWeb容器/JsSDK shareAPI)
public protocol ShareH5Service: AnyObject {
    /// 统一H5分享接口
    /// 收敛处理loading，图片压缩上传，新旧分享Type逻辑
    /// - Parameters:
    ///   - context: 上下文数据信息
    ///   - successHandler: 分享成功
    ///   - errorHandler: 分享失败
    func share(
        with context: ShareH5Context,
        successHandler: @escaping () -> Void,
        errorHandler: @escaping (Error?) -> Void
    )
}

/// H5分享(H5网页/H5网页应用/H5 JS-SDK API)时的相关数据上下文
public struct ShareH5Context {
    /// 图标（或截图）信息
    public enum Icon {
        case url(String)
        case data(Data)
    }

    /// 分享类型
    public enum ShareType {
        case h5         // H5网页
        case h5App      // H5应用
        case h5API      // H5 JSSDK API
    }

    /// 分享类型
    public var type: ShareType
    /// H5应用的appId，可选参数
    public var appId: String?
    /// 分享的链接，必选参数
    public var url: String
    /// 分享标题，必选参数
    public var title: String
    /// 分享内容，可选参数
    public var desc: String?
    /// 分享图标（或AppPage截图）, 可选参数
    public var icon: Icon?
    /// 目标容器VC，必选参数
    public var targetVC: UIViewController

    public init(
        type: ShareType,
        appId: String? = nil,
        url: String,
        title: String,
        desc: String? = nil,
        icon: Icon? = nil,
        targetVC: UIViewController
    ) {
        self.type = type
        self.appId = appId
        self.url = url
        self.title = title
        self.desc = desc
        self.icon = icon
        self.targetVC = targetVC
    }

    /// 转换为已有路由的分享类型
    public func shareH5Type(with iconToken: String?) -> ShareAppCardType {
        return .h5(appID: appId, title: title, iconToken: iconToken, desc: desc ?? "", url: url)
    }

    /// 转换为已有路由的分享类型
    public func shareAppPageType(with appId: String, iconToken: String?) -> ShareAppCardType {
        return .appPage(appID: appId, title: title, iconToken: iconToken, url: url, appLinkHref: nil, options: .None)
    }
}
public extension ShareH5Context.ShareType {
    /// 埋点参数
    var eventTypeString: String {
        switch self {
        case .h5:
            return "simple"
        case .h5App:
            return "app_normal"
        case .h5API:
            return "app_customize"
        }
    }

    var opTracking: String {
        switch self {
        case .h5:
            return "opshare_web_pageshare"
        case .h5App:
            return "opshare_web_app_pageshare"
        case .h5API:
            return "opshare_h5_sdk_api"
        }
    }
}
