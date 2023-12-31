//
//  LiveDependency.swift
//  ByteViewDependency
//
//  Created by kiri on 2021/7/1.
//

import Foundation

/// 直播相关依赖
public protocol LiveDependency {
    /// 是否正在直播
    var isLiving: Bool { get }
    /// 停止直播
    func stopLive()
    /// 直播小窗埋点
    func trackFloatWindow(isConfirm: Bool)
}
