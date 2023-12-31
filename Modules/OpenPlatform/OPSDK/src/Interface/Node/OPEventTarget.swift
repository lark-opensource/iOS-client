//
//  OPEventTarget.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/5.
//

import Foundation

/// 事件拦截和处理协议
@objc public protocol OPEventTargetProtocol: NSObjectProtocol {
    
    // 拦截来自 parent 往下的事件
    func interceptEvent(event: OPEvent, callback: OPEventCallback) -> Bool
    
    // 处理来自 child 往上的事件
    func handleEvent(event: OPEvent, callback: OPEventCallback) -> Bool
    
}

/// 事件发送协议
@objc public protocol OPEventNodeProtocol: NSObjectProtocol {
    
    /// 发送事件
    func sendEvent(eventName: String, params: [String: AnyHashable], callbackBlock: @escaping OPEventCallbackBlock, context: OPEventContext) -> Bool
    
    /// 在正式发送事件之前，准备事件上下文
    func prepareEventContext(context: OPEventContext)
}
