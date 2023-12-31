//
//  HideableReachPoint.swift
//  UGContainer
//
//  Created by mochangxing on 2021/2/2.
//

import Foundation

/// 可关闭的ReachPoint
public protocol HideableReachPoint: Hideable, ReachPoint {}

extension HideableReachPoint {
    /// 主动关闭ReachPoint
    public func hide() {
        hideReachPoint(reachPointId: reachPointId, reachPointType: Self.reachPointType)
    }
}
