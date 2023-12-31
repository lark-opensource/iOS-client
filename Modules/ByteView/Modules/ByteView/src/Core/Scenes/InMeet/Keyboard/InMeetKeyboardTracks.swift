//
//  InMeetKeyboardTracks.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/4/18.
//

import Foundation
import ByteViewTracker

// 埋点文档：https://bytedance.feishu.cn/sheets/Od4Psg4XxhXMiwtdXcAcl8F7nmd

/// 点击类型
enum InMeetKeyboardShortcutClickType: String {
    /// 开关麦克风
    /// Command + Shift + D
    case muteMicrophone = "mic"
    /// 开关摄像头
    /// Command + Shift + V
    case muteCamera = "cam"
}

/// 场景类型
enum InMeetKeyboardShortcutLocationType: String {
    /// 会前预览页
    case preview = "preview_page"
    /// 会中主窗
    case onTheCall = "onthecall"
    /// 会前/会中等候室
    case lobby = "waiting_room"
}

final class KeyboardTrack {

    /// 点击快捷键
    /// - Parameters:
    ///   - clickType: 点击类型
    ///   - isOn: 切换后的开关状态
    ///   - locationType: 场景类型
    static func trackClickShortcut(with clickType: InMeetKeyboardShortcutClickType,
                                   to isOn: Bool,
                                   from locationType: InMeetKeyboardShortcutLocationType) {
        VCTracker.post(name: .vc_meeting_shortcut_click,
                       params: [.click: clickType.rawValue,
                                .option: isOn.stringValue,
                                "is_minimised": "false",
                                "location": locationType.rawValue])
    }

}
