//
//  LarkLiveEvent.swift
//  ByteView
//
//  Created by tuwenbo on 2021/1/27.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

// 定义：https://bytedance.feishu.cn/docx/doxcnz6dniKcX2MxUzAUEhYvoag
enum LarkLiveEvent: Int {
    case unknown = 0
    case ready
    case play
    case pause
    case end
    case error
    case muted
    case streamChange
    case danmakuChange
    case jsReady
    case liveCanplay            // 直播可以播放
    case liveLoadedData           // 直播缓冲足够数据
    case playerLayoutChange
    case moreDrawerVisibleChange
    case webviewLoaded             // 网页加载完毕
    case nativeToastVisibleChange  // 移动端Toast状态发生改变
    case changeWindowOrientation = 17 // 设置直播小窗方向
}

enum PlayerType: String {
  case unknown = "unknown"
  case live = "live"
  case playback = "playback"
}

enum NativeToWebEvent: Int {
    case unknown = 0
    case normalMode   // v1
    case miniMode     // v1
    case containerModeChange  // v2
//    case containerOrientationChange   // 全屏优化

    enum ContainerMode: Int {
        case unknown = 0
        case normalMode // 切换普通模式
        case miniMode // 切换小窗模式
    }
    
    // 全屏优化
//    enum OrientationChange: Int {
//        case unknown = 0
//        case vertical
//        case horizontal
//    }
}

