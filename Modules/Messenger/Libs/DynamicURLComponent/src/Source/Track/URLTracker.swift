//
//  URLTracker.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/23.
//

import Foundation
import Homeric
import RustPB
import LarkModel
import LarkCore
import LKCommonsTracker

// https://bytedance.feishu.cn/sheets/shtcnd9NLwJ68HwANMeYSe4ykRg
final class URLTracker {
    // URL渲染发生动作事件
    enum ClickType: String {
        case pageClick = "page_click" // 渲染页面上的点击
        case openUrl = "open_url" // 打开URL链接
        case selectItem = "select_item" // 下拉选择
        case button = "button" // button点击
        case avatar = "icon" // 头像点击
        case playVideo = "play_video" // 视频播放
        case text = "text" // text点击
    }

    static func trackRenderClick(entity: URLPreviewEntity?,
                                 extraParams: [AnyHashable: Any],
                                 clickType: ClickType,
                                 componentID: String,
                                 actionID: String? = nil) {
        guard let entity = entity else { return }
        let url = entity.url.hasIos ? entity.url.ios : entity.url.url
        var domainPath = url
        if let url = URL(string: url), let host = url.host {
            domainPath = host.appending(url.path)
        }
        // 未接入URL中台的也需要变成中台的样式，previewID统一上报none
        let previewID = entity.previewID.isEmpty ? "none" : entity.previewID
        var params: [AnyHashable: Any] = ["click": clickType.rawValue,
                                          "url_domain_path": domainPath,
                                          "url_id": previewID,
                                          "app_id": "\(entity.appInfo.appID)",
                                          "scene_type": "\(entity.appInfo.sceneType)",
                                          "component_id": componentID,
                                          "target": "none"]
        params += extraParams
        if let actionID = actionID {
            params["action_id"] = actionID
        }
        Tracker.post(TeaEvent(Homeric.IM_URL_RENDER_CLICK, params: params))
    }
}
