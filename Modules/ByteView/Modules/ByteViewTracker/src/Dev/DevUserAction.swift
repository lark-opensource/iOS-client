//
//  TrackUserActon.swift
//  ByteViewTracker
//
//  Created by kiri on 2022/1/16.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

extension DevTrackEvent {

    /// 用户操作（点击）
    public enum UserAction: String {
        /// Audio相关
        case clickAudioRoute

        // ====== 麦克风操作 ======

        /// 会中改变麦克风状态
        case change_inmeeting_microphone
        /// 收到服务端改变麦克风的推送，包括 unmute 请求成功、主持人 mute 自己
        case microphone_push
        /// 麦克风 unmute 请求的通用错误埋点
        case change_microphone_failed
        /// 放手
        case mic_hands_down

        /// 请求某人静音/取消静音
        case request_mic_mute
        /// 请求全员静音/取消静音
        case request_mic_mute_all

        // ====== 摄像头操作 ======

        /// 会中改变摄像头状态
        case change_inmeeting_camera
        /// 收到服务端改变摄像头的推送，包括 unmute 请求成功、主持人 mute 自己
        case camera_push
        /// 摄像头 unmute 请求的通用错误埋点
        case change_camera_failed
        /// 请求某人打开/关闭的摄像头
        case request_camera_mute
    }
}
