//
//  SketchTracks.swift
//  ByteView
//
//  Created by kiri on 2020/10/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork

final class SketchTracks {

    private static var annotatePopup = TrackEventName.vc_annotate_popup

    /// 点击标注
    static func trackClickAnnotate(meetType: MeetingType) {
        VCTracker.post(name: meetType.trackName, params: [.action_name: "annotate"])
    }

    /// 点击撤销
    /// - Parameters:
    ///   - isHost: 1：主持人
    ///             2：联席主持人
    ///             0：都不是
    ///   - isPresenter: 0
    static func trackClickUndo(isHost: Int = 0, isPresenter: Int = 0) {
        VCTracker.post(name: .vc_annotate_control_bar,
                       params: [.action_name: "undo",
                                "is_host": isHost,
                                "is_presenter": isPresenter,
                                "is_sharer": 0])
    }

    /// 擦除图形
    static func trackEraseAction() {
        VCTracker.post(name: .vc_annotate_usage_monitor,
                       params: ["is_sharer": "false", "action_name": "eraser"])
    }

    /// 画笔使用次数
    static func trackDraw(_ draw: String, color: String) {
        VCTracker.post(name: .vc_annotate_usage_monitor,
                       params: ["is_sharer": 0, "draw": draw, "color": color])
    }

    /// 请求共享人开启 Accessibility
    static func trackRequestAccessibility() {
        VCTracker.post(name: annotatePopup,
                       params: ["is_sharer": 0, .action_name: "send_request"])

    }

    /// 取消请求 Accessibility
    static func trackCancelAccessibility() {
        VCTracker.post(name: annotatePopup,
                       params: ["is_sharer": 0, .action_name: "cancel"])
    }

    /// 标注引导弹窗，被共享者首次使用标注时，点击标注按钮触发弹窗上报
    static func trackOnboardingToast() {
        VCTracker.post(name: annotatePopup,
                       params: ["is_sharer": 0, .action_name: "annotate_onboarding_toast"])
    }

    /// 点击撤销
    /// - Parameters:
    /// - is_sharer: 是否是共享人
    static func trackClickSave(is_sharer: Bool = false) {
        VCTracker.post(name: .vc_annotate_usage_monitor,
                       params: [.action_name: "save",
                                "is_sharer": is_sharer ? 1 : 0])
    }
}
