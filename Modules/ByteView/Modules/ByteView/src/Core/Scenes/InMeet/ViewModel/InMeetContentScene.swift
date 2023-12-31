//
//  InMeetContentScene.swift
//  ByteView
//
//  Created by kiri on 2021/4/11.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

enum InMeetContentScene {
    case initial
    case flow // 视频流
    case follow // 共享内容
    case shareScreen // 共享屏幕
    case selfShareScreen // 自己共享屏幕
    case flowAndShareScreen // 视频流加共享屏幕
    case whiteboard // 白板
    case flowAndWhiteboard // 视频流加白板
    case webSpace // 企业信息
}
