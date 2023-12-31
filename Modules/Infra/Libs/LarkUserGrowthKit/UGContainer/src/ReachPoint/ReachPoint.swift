//
//  ReachPoint.swift
//  UGContainer
//
//  Created by mochangxing on 2021/1/22.
//

import Foundation
import SwiftProtobuf
import EENavigator

/// ReachPoint类型 唯一标识
public typealias ReachPointType = String

/// ReachPoint必须提供Identify
public protocol Identifiable {
    static var reachPointType: ReachPointType { get }
}

/// Convenience 初始化
public protocol ConvenienceInitable {
    /// 初始化方法
    init()
}

public protocol ReachPoint: AnyObject, ConvenienceInitable, Identifiable {

    associatedtype ReachPointModel

    var reachPointId: String { get set }

    func onCreate()

    func onShow()

    func onHide()

    func onDestroy()

    func onUpdateData(data: ReachPointModel) -> Bool

    static func decode(payload: Data) -> ReachPointModel?

    func setNavigator(navigator: Navigatable)
}

public extension ReachPoint {
    func setNavigator(navigator: Navigatable) {}
}

private struct AssociatedKeys {
    static var reachPointIdKey = "ReachPoint.reachPointIdKey"
    static var containerSeviceKey = "ReachPoint.containerSeviceKey"
}

extension ReachPoint {
    var containerSevice: PluginContainerService? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.containerSeviceKey) as? PluginContainerService ?? nil
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.containerSeviceKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

public extension ReachPoint {
    /// 默认实现
    func onCreate() {}
    /// 默认实现
    func onDestroy() {}

    var reachPointId: String {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.reachPointIdKey) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.reachPointIdKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    func reportEvent(_ event: ReachPointEvent) {
        containerSevice?.reportEvent(event: event)
    }
}
