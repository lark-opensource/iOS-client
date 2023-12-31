//
//  TCPreviewTracker.swift
//  LarkMessageCore
//
//  Created by 袁平 on 2021/6/2.
//

import Foundation
import Homeric
import RustPB
import LarkModel
import LarkCore
import LKCommonsTracker

// https://bytedance.feishu.cn/sheets/shtcnd9NLwJ68HwANMeYSe4ykRg
final class TCPreviewTracker {
    // URL渲染
    static func trackUrlRender(entity: URLPreviewEntity, extraParams: [AnyHashable: Any]) {
        let url = entity.url.hasIos ? entity.url.ios : entity.url.url
        // 未接入URL中台的也需要变成中台的样式，previewID统一上报none
        let previewID = entity.previewID.isEmpty ? "none" : entity.previewID
        var params: [AnyHashable: Any] = [
            "url_domain_path": domainPath(url: url),
            "url_id": previewID,
            "version": "\(entity.version)"
        ]
        params += extraParams
        Tracker.post(TeaEvent(Homeric.IM_URL_RENDER_VIEW, params: params))
    }

    // URL渲染发生动作事件
    enum ClickType: String {
        case openPage = "open_page" // 点击卡片打开
        case pageClick = "page_click" // 渲染页面上的点击
        case openUrl = "open_url" // 打开URL链接
        case selectItem = "select_item" // 下拉选择
        case button = "button" // button点击
        case avatar = "icon" // 头像点击
        case playVideo = "play_video" // 视频播放
    }

    static func trackRenderClick(entity: URLPreviewEntity, extraParams: [AnyHashable: Any], clickType: ClickType, componentID: String) {
        let url = entity.url.hasIos ? entity.url.ios : entity.url.url

        // 未接入URL中台的也需要变成中台的样式，previewID统一上报none
        let previewID = entity.previewID.isEmpty ? "none" : entity.previewID
        var params: [AnyHashable: Any] = [
            "click": clickType.rawValue,
            "url_domain_path": domainPath(url: url),
            "url_id": previewID,
            "app_id": "\(entity.appInfo.appID)",
            "scene_type": "\(entity.appInfo.sceneType)",
            "component_id": componentID,
            "target": "none"
        ]
        params += extraParams
        Tracker.post(TeaEvent(Homeric.IM_URL_RENDER_CLICK, params: params))
    }

    static func domainPath(url: String) -> String {
        var domainPath = url
        if let url = URL(string: url), let host = url.host {
            domainPath = host.appending(url.path)
        }
        return domainPath
    }
}
