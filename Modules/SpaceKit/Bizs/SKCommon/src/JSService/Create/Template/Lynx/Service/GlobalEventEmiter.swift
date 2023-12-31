//
//  GlobalEventEmiter.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2022/3/30.
//  


import Foundation
import SKFoundation

/// 用于全局事件发送，通过setup方法配置对应的lynxView，
/// 通过jsRuntimeDidReady方法告知js runtime已准备就绪。
/// 只有当配置了lynxView，且js runtime准备就绪，才开始发送
/// 全局事件。否则事件会被暂存起来。
public final class GlobalEventEmiter {
    public struct Event {
        let name: String
        let params: [String: Any]
        let canBeReplace: Bool
        
        /// 初始化方法
        /// - Parameters:
        ///   - name: 事件名
        ///   - params: 参数
        ///   - canBeReplace: 后续再往暂存队列里添加同名事件时，当前事件能否被丢弃
        public init(name: String, params: [String: Any], canBeReplace: Bool = true) {
            self.name = name
            self.params = params
            self.canBeReplace = canBeReplace
        }
    }
    
    private var lynxView: LynxEnvManager.LynxView?
    private var isJSRuntimeReady = false
    private var eventPool: [Event] = []
    private let opQueue = DispatchQueue(label: "com.ccm.lynx.globalEventEmiter")
    
    /// 初始化
    init(_ events: [Event] = []) {
        events.forEach { [weak self] event in
            self?.send(event: event, needCache: true)
        }
    }
    /// 配置lynxView
    /// - Parameter lynxView: LynxView
    func setup(lynxView: LynxEnvManager.LynxView) {
        opQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.lynxView == nil else {
                spaceAssertionFailure("已设置lynxView")
                return
            }
            self.lynxView = lynxView
        }
    }
    
    /// 通知emiter，js runtime准备好了
    func jsRuntimeDidReady() {
        opQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.lynxView != nil else {
                spaceAssertionFailure("未设置lynxView")
                return
            }
            guard !self.isJSRuntimeReady else {
                return
            }
            self.isJSRuntimeReady = true
            self.sendPoolAllEvents()
        }
    }
    
    /// 发送全局事件
    /// - Parameter event: 全局事件
    /// - Parameter needCache: 若js runtime未准备好，是否把event暂存
    public func send(event: Event, needCache: Bool = false) {
        opQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.isJSRuntimeReady else {
                DocsLogger.info("lynx view js runtime未准备好")
                if needCache {
                    self.addEventToPool(event)
                }
                return
            }
            self.lynxView?.sendEvent(event.name, params: event.params)
            DocsLogger.info("send global event:\(event)")
        }
    }
    
    /// 丢弃所有未发送的event
    func drain() -> [Event] {
        var events: [Event] = []
        opQueue.sync { [weak self] in
            guard let self = self else { return }
            events = self.eventPool
            self.eventPool.removeAll()
        }
        return events
    }
    
    private func addEventToPool(_ event: Event) {
        eventPool.removeAll(where: { $0.canBeReplace && $0.name == event.name })
        eventPool.append(event)
    }
    private func sendPoolAllEvents() {
        eventPool.forEach {
            lynxView?.sendEvent($0.name, params: $0.params)
            DocsLogger.info("send global event:\($0)")
        }
        eventPool.removeAll()
    }
}
