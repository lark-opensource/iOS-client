//
//  DevCategory.swift
//  ByteViewTracker
//
//  Created by kiri on 2022/1/16.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

extension DevTrackEvent {

    /// 分类
    public enum Category: String, Hashable {
        /// 预览页
        case preview
        /// 共享文档
        case magic_share
        /// 会议核心场景
        case meeting
        /// 浮窗相关，这里特指FloatingWindow
        case window
        /// 网络状况
        case network
        /// 音频
        case audio
        /// 模块本身
        case module
        /// 麦克风相关操作
        case microphone_operation
        /// 摄像头相关操作
        case camera_operation

        /// 视频流订阅渲染相关
        case video_stream

        /// CallKit 相关
        case callkit
    }

    /// 子分类
    public enum Subcategory: String, Hashable {
        /// 状态机
        case state
        /// RTC
        case rtc
    }
}
