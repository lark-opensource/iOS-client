//
//  ShareMonitor.swift
//  LarkSnsShare
//
//  Created by shizhengyu on 2020/12/3.
//

import Foundation
import LKCommonsTracker
import LKCommonsLogging
import Homeric

final class ShareMonitor {
    static let logger = Logger.log(ShareMonitor.self, category: "lark.sns.share.wrapper.monitor")
    static func shareTracing(
        by traceId: String?,
        isSuccess: Bool,
        contentType: ShareContentType,
        itemType: LarkShareItemType,
        errorCode: ShareResult.ErrorCode? = nil,
        errorMsg: String? = nil
    ) {
        var category: [AnyHashable: Any] = [:]
        var extra: [AnyHashable: Any] = [:]
        if isSuccess {
            category = [
                "trace_id": traceId ?? "unknown",
                "succeed": "true",
                "type": contentType.rawValue,
                "item": itemType.rawValue
            ]
        } else {
            category = [
                "trace_id": traceId ?? "unknown",
                "succeed": "false",
                "type": contentType.rawValue,
                "item": itemType.rawValue
            ]
            if let errCode = errorCode {
                category["error_code"] = errCode.rawValue
            }
            if let errMsg = errorMsg {
                extra["error_msg"] = errMsg
            }
        }
        ShareMonitor.logger.info("""
            [LarkSnsShare] share tracing \(isSuccess ? "success" : "fail"),
            traceId = \(traceId ?? "unknown"),
            isSuccess = \(isSuccess ? "true" : "false"),
            contentType = \(contentType.rawValue),
            itemType = \(itemType.rawValue),
            errorCode = \(errorCode?.rawValue ?? 0),
            errorMsg = \(errorMsg ?? "")
        """)
        let event = SlardarEvent(
            name: "ug_share_component",
            metric: [:],
            category: category,
            extra: extra
        )
        Tracker.post(event)
    }
}

/// UD统一分享面板埋点
/// https://bytedance.feishu.cn/sheets/shtcnhvkZQYhBV1EM5sEhPGY2hc
final class SharePanelTracker {
    /// [分享面板]页面展示
    static func trackerPublicSharePanelView(productLevel: String,
                                            scene: String) {
        var params: [AnyHashable: Any] = [:]
        params["product_level"] = productLevel
        params["scene"] = scene
        Tracker.post(TeaEvent(Homeric.PUBLIC_SHARE_PANEL_VIEW, params: params))
    }
    /// [分享面板-确认] 页面展示
    static func trackerPublicSharePanelConfirmView(productLevel: String,
                                                   scene: String) {
        var params: [AnyHashable: Any] = [:]
        params["product_level"] = productLevel
        params["scene"] = scene
        Tracker.post(TeaEvent(Homeric.PUBLIC_SHARE_PANEL_CONFIRM_VIEW, params: params))
    }
    /// [分享面板-确认] 页面点击
    static func trackerPublicSharePanelConfirmViewClick(productLevel: String,
                                                        scene: String,
                                                        click: String,
                                                        extra: [AnyHashable: Any] = [:]) {
        var params: [AnyHashable: Any] = [:]
        params["product_level"] = productLevel
        params["scene"] = scene
        params["click"] = click
        params += extra
        Tracker.post(TeaEvent(Homeric.PUBLIC_SHARE_PANEL_CONFIRM_CLICK, params: params))
    }
    /// 「分享面板-图片分享」页面展示
    static func trackerPublicSharePanelPicView(productLevel: String,
                                               scene: String) {
        var params: [AnyHashable: Any] = [:]
        params["product_level"] = productLevel
        params["scene"] = scene
        Tracker.post(TeaEvent(Homeric.PUBLIC_SHARE_PANEL_PIC_VIEW, params: params))
    }
    /// 「分享面板-图片分享」页面发生动作事件
    static func trackerPublicSharePanelClick(productLevel: String,
                                             scene: String,
                                             clickItem: LarkShareItemType?,
                                             clickOther: String?,
                                             panelType: PanelType,
                                             extra: [AnyHashable: Any] = [:]) {
        var params: [AnyHashable: Any] = [:]
        params["product_level"] = productLevel
        params["scene"] = scene
        if let item = clickItem {
            switch item {
            case .wechat:
                params["click"] = "share_to_wechat"
                switch panelType {
                case .actionPanel:
                    params["target"] = "public_share_panel_confirm_view"
                case .imagePanel:
                    params["target"] = "none"
                }
            case .weibo:
                params["click"] = "share_to_weibo"
                switch panelType {
                case .actionPanel:
                    params["target"] = "public_share_panel_confirm_view"
                case .imagePanel:
                    params["target"] = "none"
                }
            case .qq:
                params["click"] = "share_to_qq"
                switch panelType {
                case .actionPanel:
                    params["target"] = "public_share_panel_confirm_view"
                case .imagePanel:
                    params["target"] = "none"
                }
            case .timeline:
                params["click"] = "share_to_wechat_moments"
                switch panelType {
                case .actionPanel:
                    params["target"] = "public_share_panel_pic_view"
                case .imagePanel:
                    params["target"] = "none"
                }
            case .copy:
                params["click"] = "copy_link"
                switch panelType {
                case .actionPanel:
                    params["target"] = "none"
                case .imagePanel:
                    break
                }
            case .save:
                params["click"] = "download"
                switch panelType {
                case .actionPanel:
                    break
                case .imagePanel:
                    params["target"] = "none"
                }
            case .shareImage:
                params["click"] = "share_with_pic"
                switch panelType {
                case .actionPanel:
                    params["target"] = "public_share_panel_pic_view"
                case .imagePanel:
                    break
                }
            case .more:
                params["click"] = "more"
                switch panelType {
                case .actionPanel:
                    params["target"] = "none"
                case .imagePanel:
                    params["target"] = "none"
                }
            case .custom(let customShareContext):
                if customShareContext.identifier == "inapp" {
                    params["click"] = "share_to_chat"
                    switch panelType {
                    case .actionPanel:
                        params["target"] = "none"
                    case .imagePanel:
                        params["target"] = "none"
                    }
                }
            case .unknown: break
            }
        }
        if let click = clickOther {
            params["click"] = click
            params["target"] = "none"
        }
        params += extra
        switch panelType {
        case .actionPanel:
            Tracker.post(TeaEvent(Homeric.PUBLIC_SHARE_PANEL_CLICK, params: params))
        case .imagePanel:
            Tracker.post(TeaEvent(Homeric.PUBLIC_SHARE_PANEL_PIC_CLICK, params: params))
        }

    }
}
