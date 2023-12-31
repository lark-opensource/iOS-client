//
//  TCPreviewRenderTracker.swift
//  LarkMessageCore
//
//  Created by 袁平 on 2022/4/22.
//

import UIKit
import Foundation
import RustPB
import LarkCore
import LarkModel
import TangramService
import AppReciableSDK
import LKCommonsTracker
import ThreadSafeDataStructure

// https://bytedance.feishu.cn/docx/doxcn6tk3uHpTETngpb2egjsF0d

struct TCPreviewRenderInfo {
    // 是否需要上报卡片渲染耗时，为了避免频繁加解锁
    var renderNeedTrack: Bool = false
    var componentTreeBuildCost: CFTimeInterval = 0
    var uiRenderStartTime: CFTimeInterval = 0
    var uiRenderEndTime: CFTimeInterval = 0
    var totalCostStartTime: CFTimeInterval = 0
    var totalCostEndTime: CFTimeInterval = 0
    var componentsCount: Int = 0
    var templateID: String = ""
    var isLazyLoad: Bool = false
    var url: String = ""
}

final class TCPreviewRenderTracker {
    private var startTimes: SafeDictionary<String, CFTimeInterval> = [:] + .readWriteLock

    func startTrack(message: Message) {
        // 卡片从无到有时才上报埋点，Entity跟着Message一起下来时，不上报
        let entities = message.urlPreviewEntities
        let previewIDs = message.orderedPreviewIDs.filter({ entities[$0] == nil })
        guard !previewIDs.isEmpty else { return }
        previewIDs.forEach { previewID in
            if startTimes[previewID] == nil {
                startTimes[previewID] = CACurrentMediaTime()
            }
        }
    }

    func initRenderInfo(entity: URLPreviewEntity, hangPoints: [String: RustPB.Basic_V1_UrlPreviewHangPoint]) -> TCPreviewRenderInfo? {
        guard let startTime = startTimes[entity.previewID],
              let hangPoint = hangPoints.values.first(where: { $0.previewID == entity.previewID }) else { return nil }
        // 需要重置开始时间，因为CellVM会销毁，可能导致开始时间和结束时间不匹配造成totalCost异常
        startTimes[entity.previewID] = nil
        return TCPreviewRenderInfo(renderNeedTrack: true,
                                   totalCostStartTime: startTime,
                                   isLazyLoad: hangPoint.isLazyLoad,
                                   url: hangPoint.url)
    }

    static func trackRender(previewID: String, info: TCPreviewRenderInfo?) {
        guard let info = info else { return }
        DispatchQueue.global().async {
            let netStatus = AppReciableSDK.shared.getActualNetStatus(start: info.totalCostStartTime, end: info.totalCostEndTime)
            let isInBackground = AppReciableSDK.shared.isInBackground(start: info.totalCostStartTime, end: info.totalCostEndTime)
            let uiRenderCost = Int((info.uiRenderEndTime - info.uiRenderStartTime) * 1000)
            let totalCost = Int((info.totalCostEndTime - info.totalCostStartTime) * 1000)
            var params: [String: Any] = [
                "net_status": netStatus,
                "app_status": TCPreviewTrackAppStatus(isInBackground: isInBackground).rawValue,
                "preview_id": previewID,
                "components_count": info.componentsCount,
                "url_domain_path": TCPreviewTracker.domainPath(url: info.url),
                "is_lazy_load": info.isLazyLoad ? 1 : 0,
                "component_tree_build_cost": "\(Int(info.componentTreeBuildCost * 1000))",
                "ui_render_cost": "\(uiRenderCost)",
                "total_cost": "\(totalCost)",
                "render_action": 0
            ]
            if !URLPreviewAdaptor.isLocalTemplate(templateID: info.templateID) {
                params["template_id"] = info.templateID
            }
            Tracker.post(TeaEvent("url_preview_card_render_dev", params: params))
        }
    }
}
