//
//  LarkLiveData.swift
//  ByteView
//
//  Created by tuwenbo on 2021/1/26.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation


struct LarkLiveData {
    var liveHost: String?
    var liveID: String?
    var liveLink: String?
    var streamLink: String?
    var liveState: LivePlayerState = .unknown
    var muted = false
    var danmaku = false
    // 下面仨属性为全屏优化
//    var layout: String?
//    var visible = false
//    var from: String?
    
    var delay: Int?
    var content: String?
    
    var playerType: String?
    var floatViewOrientation: String?
}


// 全屏优化
//enum LayoutType: String {
//    case detail
//    case vertical
//    case horizontal
//}
//
//enum LayoutFrom: String {
//    case system
//    case user
//}


enum LivePlayerState {
    case unknown, play, pause, end
}

enum LiveMode: Int {
    case floatWindow
    case landscape
    case portrait
}
