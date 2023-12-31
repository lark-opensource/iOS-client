//
//  Hideable.swift
//  UGContainer
//
//  Created by mochangxing on 2021/2/2.
//

import Foundation

typealias SeviceProvider = () -> PluginContainerService?

private struct AssociatedKeys {
    static var seviceProviderKey = "HideableReachPoint.seviceProviderKey"
}

/// 可主动关闭ReachPoint
public protocol Hideable {
    /// 主动关闭ReachPoint
    func hideReachPoint(reachPointId: String, reachPointType: String)
}

extension Hideable {
    /// 关闭ReachPoint
    public func hideReachPoint(reachPointId: String, reachPointType: String) {
        containerSeviceProvider?()?.hideReachPoint(reachPointId: reachPointId,
                                                  reachPointType: reachPointType)
    }

    var containerSeviceProvider: SeviceProvider? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.seviceProviderKey) as? SeviceProvider
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.seviceProviderKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}
