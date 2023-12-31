//
//  DocsPermissionEvent.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/4/19.
//  


import Foundation
import SKFoundation

/// 文档权限变化事件
public protocol DocsPermissionEventObserver: AnyObject {
    
    func onCopyPermissionUpdated(canCopy: Bool)
    
    func onViewPermissionUpdated(oldCanView: Bool, newCanView: Bool) // 可选实现
    
    /// 文档宿主或者文档同步块captureAllowed权限发生变更时的通知。
    /// 目前宿主文档和同步块权限都能同时影响宿主captureAllowed权限，在收到通知后需要主动获取对应宿主文档或者同步块
    /// 的captureAllowed权限
    func onCaptureAllowedUpdated()
}

public extension DocsPermissionEventObserver {
    
    func onViewPermissionUpdated(oldCanView: Bool, newCanView: Bool) {}
    func onCaptureAllowedUpdated() {}
}

/// 文档权限变化事件通知分发
public final class DocsPermissionEventNotifier {
    
    private let observers: ObserverContainer<DocsPermissionEventObserver>
    
    public var allObservers: [DocsPermissionEventObserver] { observers.all }
    
    public init() {
        observers = .init()
    }

    public func addObserver(_ o: DocsPermissionEventObserver) {
        observers.add(o)
    }

    public func removeOvserver(_ observer: DocsPermissionEventObserver) {
        observers.remove(observer)
    }
}
