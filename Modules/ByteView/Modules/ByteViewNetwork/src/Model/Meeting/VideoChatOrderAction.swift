//
//  VideoChatOrderAction.swift
//  ByteViewNetwork
//
//  Created by Tobb Huang on 2022/11/25.
//

import Foundation

/// Videoconference_V1_VideoChatOrderAction
public enum VideoChatOrderAction: Int {
    case videoChatOrderUnknown // = 0

    /// 同步主持人视频顺序
    case videoChatOrderSync // = 1

    /// 停止同步主持人视频顺序
    case videoChatOrderUnsync // = 2
}
