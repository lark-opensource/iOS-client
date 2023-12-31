//
//  WPHomeTracker.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/12/28.
//

import Foundation

extension WPHomeVCInitData {
    /// 上报时用的 version 字段
    var version: String {
        switch self {
        case .normal: return "old"
        case .lowCode: return "new"
        case .web: return "h5"
        }
    }
}

// 用户态隔离后，这个目前较为冗余，将来需要改造
final class WPHomeTracker {

    // MARK: - -

    /// 页面曝光上报
    func trackPageExpose(_ data: WPHomeVCInitData, templatePortalCount: Int) {
        let name = WPNewEvent.openplatformWorkspaceMainPageView.rawValue
        let event = WPEventReport(name: name)
            .set(key: "version", value: data.version)
            .set(key: "template_num", value: templatePortalCount)

        switch data {
        case .normal:
            /// appcenter_view 仅在老版工作台埋点
            WPEventReport(name: WPEvent.appcenter_view.rawValue).post()
            break
        case .lowCode(let lowCode):
            event.set(key: WPEventNewKey.templateId.rawValue, value: lowCode.id)
            break
        case .web(let web):
            event.set(key: WPEventNewKey.templateId.rawValue, value: web.id)
            event.set(key: WPEventNewKey.appId.rawValue, value: web.refAppId)
        }

        event.post()
    }

    // MARK: - -

    /// 页面停留时长上报
    func trackPageStayDurationIfNeeded(_ data: WPHomeVCInitData, duration: Int) {
        guard duration > 0 else {
            return
        }
        let event = WPEventReport(
            name: WPNewEvent.openplatformWorkspaceMonitorReportView.rawValue
        )
        event.set(key: "version", value: data.version)
        event.set(key: "duration", value: "\(duration)")

        switch data {
        case .normal, .lowCode:
            break
        case .web(let web):
            event.set(key: WPEventNewKey.appId.rawValue, value: web.refAppId)
        }

        event.post()
    }
}
