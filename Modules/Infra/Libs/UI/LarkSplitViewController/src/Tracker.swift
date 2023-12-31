//
//  Tracker.swift
//  LarkSplitViewController
//
//  Created by 李晨 on 2020/12/24.
//

import UIKit
import Foundation
import Homeric
import LKCommonsTracker

/// 全屏埋点工具
public final class Tracker {
    public enum PanState: String {
        case fullscreenFocus = "fullscreen_focus"    // 全屏状态 - 专注模式
        case fullscreenNormal = "fullscreen_normal"   // 全屏状态 - 非专注模式
        case halfscreenNormal = "halfscreen_normal"   // 非全屏状态 - 普通模式
    }
    public enum FullscreenType: String {
        case focus  // 专注模式
        case normal // 非专注模式
    }
    public enum InteractType: String {
        case button
        case handle
    }

    /// 全屏按钮展示埋点
    /// scene 为展示场景
    /// isFold 代表全屏状态, isFold 为 true 代表 展示展开按钮， 为 false 代表 展示收起按钮
    public static func trackFullScreenItemShow(scene: String?, isFold: Bool) {
        var params: [AnyHashable: Any] = [:]
        if let scene = scene {
            params["window_type"] = scene
        }

        if isFold {
            LKCommonsTracker.Tracker.post(
                TeaEvent(
                    Homeric.CORE_TABLET_FULLSCREEN_BUTTON_SHOW,
                    params: params
                )
            )
        } else {
            LKCommonsTracker.Tracker.post(
                TeaEvent(
                    Homeric.CORE_TABLET_HALFSCREEN_BUTTON_SHOW,
                    params: params
                )
            )
        }
    }

    /// 全屏按钮点击埋点
    /// scene 为展示场景
    /// isFold 代表全屏状态, isFold 为 true 代表 点击展开按钮， 为 false 代表 点击收起按钮
    public static func trackFullScreenItemClick(scene: String?, isFold: Bool) {
        var params: [AnyHashable: Any] = [:]
        if let scene = scene {
            params["window_type"] = scene
        }

        if isFold {
            LKCommonsTracker.Tracker.post(
                TeaEvent(
                    Homeric.CORE_TABLET_FULLSCREEN_BUTTON_CLICK,
                    params: params
                )
            )
        } else {
            LKCommonsTracker.Tracker.post(
                TeaEvent(
                    Homeric.CORE_TABLET_HALFSCREEN_BUTTON_CLICK,
                    params: params
                )
            )
        }
    }

    public static func trackPan(scene: String, start: PanState, end: PanState) {
        var params: [String: String] = [:]
        params["window_type"] = scene
        params["gesture_type"] = "drag"
        params["start_position"] = start.rawValue
        params["stop_position"] = end.rawValue

        LKCommonsTracker.Tracker.post(
            TeaEvent(
                Homeric.IM_CORE_TABLET_FULLSCREEN_HANDLE_TOUCH,
                params: params
            )
        )
    }

    public static func trackEnterFullScreen(scene: String?, fullscreenType: FullscreenType, interactType: InteractType) {
        var params: [String: String] = [:]
        params["window_type"] = scene
        params["fullscreen_type"] = fullscreenType.rawValue
        params["interact_type"] = interactType.rawValue

        LKCommonsTracker.Tracker.post(
            TeaEvent(
                Homeric.IM_CORE_TABLET_FULLSCREEN,
                params: params
            )
        )
    }

    public static func trackLeaveFullScreen(scene: String?, interactType: InteractType) {
        var params: [String: String] = [:]
        params["window_type"] = scene
        params["halfscreen_type"] = "normal"
        params["interact_type"] = interactType.rawValue

        LKCommonsTracker.Tracker.post(
            TeaEvent(
                Homeric.IM_CORE_TABLET_HALFSCREEN,
                params: params
            )
        )
    }

    public static func trackFullScreenKeyCommand() {
        LKCommonsTracker.Tracker.post(TeaEvent(Homeric.PUBLIC_KEYBOARD_SHORTCUT_CLICK, params: ["feature": "max_secondary_window"]))
    }

    public static func trackScrollBar(location: String) {
        var params: [String: String] = [:]
        params["click"] = "drag"
        params["target"] = "none"
        params["location"] = location

        LKCommonsTracker.Tracker.post(TeaEvent(Homeric.PUBLIC_SCROLL_BAR_CLICK, params: params))
    }

    static func trackPopError(
        mode: SplitViewController.SplitMode,
        topVC: UIViewController
    ) {
        let event = SlardarEvent(
            name: "split_vc_pop_err",
            metric: [:],
            category: [
                "mode": mode.rawValue
            ],
            extra: [
                "vcType": "\(topVC.description)"
            ])
        LKCommonsTracker.Tracker.post(event)
    }

    static func trackCreateIndicatorViewError(infoCategory: [AnyHashable: Any]) {
        LKCommonsTracker.Tracker.post(SlardarEvent(name: "indicator_view_create_failed",
                                                   metric: [:],
                                                   category: infoCategory,
                                                   extra: [:]))
    }
}
