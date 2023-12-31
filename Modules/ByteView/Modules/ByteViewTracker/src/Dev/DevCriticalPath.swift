//
//  TrackCriticalPath.swift
//  ByteViewTracker
//
//  Created by kiri on 2022/1/16.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

extension DevTrackEvent {
    /// 关键路径
    public enum CriticalPath: String {

        // MARK: - meeting
        /// 会议入口
        case meeting_entry
        /// 启动预览页
        case start_preview
        /// 未入会就离开
        case leave_meeting_when_idle
        /// 创建Meeting对象
        case create_meeting_instance
        /// 释放Meeting对象
        case release_meeting_instance
        /// 状态机切换
        case enter_meeting_state
        /// 首次获得VideoChatInfo
        case receive_first_videochatinfo
        /// 获得音频首帧
        case receive_first_audioframe
        /// 获得视频首帧
        case receive_first_videoframe
        /// 获得共享屏幕首帧
        case receive_first_screenframe
        /// rtc joinChannel 成功
        case rtc_join_channel
        /// rtc rejoinChannel 成功
        case rtc_rejoin_channel
        /// rtc leaveChannel 调用完成
        case rtc_leave_channel

        // MARK: - window
        /// present
        case present_floating_window
        /// dismiss
        case dismiss_floating_window
        /// 进入小窗模式
        case enter_window_floating
        /// 进入全屏模式
        case enter_window_fullscreen
        /// window scene 发生变化
        case change_window_scene
    }
}
