//
//  OpenBGAudioTracker.swift
//  OPPlugin
//
//  Created by zhysan on 2022/6/21.
//

import Foundation
import LarkOpenPluginManager
import OPPluginManagerAdapter
import OPSDK
import LarkOpenAPIModel

// https://bytedance.sg.feishu.cn/sheets/shtlgo4g3vtMDYcFygafHvg5V7W
struct OpenBGAudioTracker {
    
    // 当浮窗展示时的埋点
    static let windowDidShowEventName = "openplatform_micro_program_background_music_view"
    
    // 当浮窗被点击时的埋点
    static let windowDidClickEventName = "openplatform_micro_program_background_music_bar_view"
    
    // 当浮窗点击出现播控页面然后进行播控事件时的埋点
    static let windowPlayControlEventName = "openplatform_micro_program_background_music_bar_click"

    // 当浮窗展示时的埋点
    static func windowDidShow(apiContext: OpenAPIContext) {
        OPMonitor(windowDidShowEventName)
            .setUniqueID(apiContext.uniqueID)
            .setPlatform(.tea)
            .tracing(apiContext.apiTrace)
            .flush()
    }
    
    static func windowDidClick(apiContext: OpenAPIContext) {
        OPMonitor(windowDidClickEventName)
            .setUniqueID(apiContext.uniqueID)
            .setPlatform(.tea)
            .tracing(apiContext.apiTrace)
            .flush()
    }
    
    enum WindowPlayControlEvent {
        enum PlayControlValue: String {
            case stop
            case `continue`
        }
        case title
        case playControl(PlayControlValue)
        case close
        
        var moniterData: [String: String] {
            switch self {
            case .title:
                return ["click": "title"]
            case .playControl(let playControlValue):
                return [
                    "click": "play_control",
                    "control_value": playControlValue.rawValue
                ]
            case .close:
                return ["click": "close"]
            }
        }
    }
    
    static func windowPlayControl(apiContext: OpenAPIContext, controlEvent: WindowPlayControlEvent) {
        OPMonitor(windowPlayControlEventName)
            .setUniqueID(apiContext.uniqueID)
            .setPlatform(.tea)
            .tracing(apiContext.apiTrace)
            .addMap(controlEvent.moniterData)
            .flush()
    }
}
