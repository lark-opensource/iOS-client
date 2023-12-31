//
//  InlinePreviewRenderTrack.swift
//  LarkMessageCore
//
//  Created by 袁平 on 2022/4/20.
//

import UIKit
import Foundation
import RustPB
import LarkCore
import LarkModel
import AppReciableSDK
import LarkMessageBase
import LKCommonsTracker

// https://bytedance.feishu.cn/docx/doxcn6tk3uHpTETngpb2egjsF0d

// Inline渲染埋点
public struct InlinePreviewRenderTrack {
    struct TrackInfo {
        var hangPoint: Basic_V1_UrlPreviewHangPoint
        var startTime: CFTimeInterval = 0
        var endTime: CFTimeInterval = 0
    }

    private var trackInfos: [String: TrackInfo] = [:]
    private var startTimeSetted: Set<String> = .init()

    public init() {}

    public mutating func setStartTime(message: Message) {
        guard !message.urlPreviewHangPointMap.isEmpty, !startTimeSetted.contains(message.id) else { return }
        startTimeSetted.insert(message.id)
        let inlines = MessageInlineViewModel.getInlinePreviewBody(message: message)
        // Inline从无到有时才上报埋点
        message.urlPreviewHangPointMap.filter({ inlines[$0.value.previewID] == nil }).values.forEach { hangPoint in
            var info = TrackInfo(hangPoint: hangPoint)
            info.startTime = CACurrentMediaTime()
            trackInfos[hangPoint.previewID] = info
        }
    }

    public mutating func setEndTime(message: Message, endTime: CFTimeInterval) {
        guard !message.urlPreviewHangPointMap.isEmpty, !trackInfos.isEmpty else { return }
        var infos = trackInfos.filter({ $0.value.endTime <= 0 })
        guard !infos.isEmpty else { return }

        let inlines = MessageInlineViewModel.getInlinePreviewBody(message: message)
        infos = infos.filter({ inlines[$0.key] != nil })
        infos.forEach { previewID, info in
            var info = info
            info.endTime = endTime
            trackInfos[previewID] = info
        }
    }

    /// 每条Inline只上报一次
    /// Returns:
    ///  - true：埋点全部上报完成
    @discardableResult
    public mutating func trackRender(contextScene: ContextScene) -> Bool {
        return trackRender(scene: contextScene.tcScene)
    }

    @discardableResult
    public mutating func trackRender(scene: String) -> Bool {
        guard !trackInfos.isEmpty else { return true }
        let infos = trackInfos.filter({ $0.value.endTime > 0 })
        infos.forEach { previewID, info in
            trackInfos[previewID] = nil
            trackRender(info: info, scene: scene)
        }
        return trackInfos.isEmpty
    }

    func trackRender(info: TrackInfo, scene: String) {
        let netStatus = AppReciableSDK.shared.getActualNetStatus(start: info.startTime, end: info.endTime)
        let isInBackground = AppReciableSDK.shared.isInBackground(start: info.startTime, end: info.endTime)
        let cost = Int((info.endTime - info.startTime) * 1000)
        Tracker.post(TeaEvent("url_preview_inline_render_dev", params: [
            "net_status": netStatus,
            "app_status": TCPreviewTrackAppStatus(isInBackground: isInBackground).rawValue,
            "scene": scene,
            "preview_id": info.hangPoint.previewID,
            "url_domain_path": domainPath(url: info.hangPoint.url),
            "is_lazy_load": info.hangPoint.isLazyLoad ? 1 : 0,
            "inline_render_cost": "\(cost)"
        ]))
    }

    func domainPath(url: String) -> String {
        var domainPath = url
        if let url = URL(string: url), let host = url.host {
            domainPath = host.appending(url.path)
        }
        return domainPath
    }

    // Inline从无到有时上报：有hangPoint但是没有Entity
    public static func needTrack(message: Message) -> Bool {
        guard !message.urlPreviewHangPointMap.isEmpty else { return false }
        let inlines = MessageInlineViewModel.getInlinePreviewBody(message: message)
        return message.urlPreviewHangPointMap.contains(where: { inlines[$0.value.previewID] == nil })
    }
}

private extension ContextScene {
    var tcScene: String {
        switch self {
        case .threadChat: return "thread"
        case .threadDetail, .replyInThread: return "thread_detail"
        case .threadPostForwardDetail: return "thread_post_forward_detail"
        case .newChat: return "chat"
        case .mergeForwardDetail: return "merge_forward"
        case .messageDetail: return "chat_detail"
        case .pin: return "pin"
        }
    }
}
