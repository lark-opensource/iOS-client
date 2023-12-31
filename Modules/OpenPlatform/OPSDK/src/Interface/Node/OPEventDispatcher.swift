//
//  OPEvent.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/5.
//

import Foundation
import LarkOPInterface
import OPFoundation

public typealias OPEventCallbackBlock = ((_ result: OPEventResult) -> Void)

public enum OPEventResultType: String {
    
    /// 成功
    case success
    
    /// 失败
    case fail
    
    /// 取消
    case cancel
    
    /// 无处理
    case noHandler
    
}

@objcMembers
public final class OPEventResult: NSObject {
    
    public fileprivate(set) var type: String = OPEventResultType.noHandler.rawValue
    
    public fileprivate(set) var data: [AnyHashable: Any]?
    
    public fileprivate(set) var error: OPError?
    
    public override var description: String {
        get {
            "OPEventResult:\(type)-\(data)"
        }
    }
    
    public required init(type: String, data: [AnyHashable: Any]? = nil, error: OPError? = nil) {
        self.type = type
        self.data = data
        self.error = error
    }
}

@objcMembers
public final class OPEventCallback: NSObject {
    
    private let callbackBlock: OPEventCallbackBlock
    
    /// 是否已经调用 callback，一个 Result 只能调用一次
    public private(set) var callbackInvoked: Bool = false
    
    public required init(callbackBlock: @escaping OPEventCallbackBlock) {
        self.callbackBlock = callbackBlock
    }
    
    deinit {
        if !callbackInvoked {
            // 还没上报，自动补充上报
            callbackNoHandler(data: ["message": "callback never been invoked"])
        }
    }
    
    /// 支持自定义回调类型
    public func callback(type: String, data: [AnyHashable: Any]?, error: OPError? = nil) {
        guard !callbackInvoked else {
            return
        }
        callbackInvoked = true
        callbackBlock(OPEventResult(type: type, data: data, error: error))
    }
    
    public func callbackSuccess(data: [AnyHashable: Any]?) {
        callback(type: OPEventResultType.success.rawValue, data: data)
    }
    
    /// 强制要求提供 Error 信息以供追溯
    public func callbackFail(data: [AnyHashable: Any]?, error: OPError?) {
        let resultType = OPEventResultType.fail
        callback(type: resultType.rawValue, data: data, error: error)
    }
    
    /// 强制要求提供 Error 信息以供追溯
    public func callbackCancel(data: [AnyHashable: Any]?, error: OPError?) {
        let resultType = OPEventResultType.cancel
        callback(type: resultType.rawValue, data: data, error: error)
    }
    
    public func callbackNoHandler(data: [AnyHashable: Any]?) {
        let resultType = OPEventResultType.noHandler
        callback(type: resultType.rawValue, data: data)
    }
}

public final class OPEventDispatcher {
    
    public func sendEvent(event: OPEvent, callback: OPEventCallback) -> Bool {
        var target: OPNodeProtocol? = event.srcNode
        
        // 构建链表
        var parents: [OPNodeProtocol] = []
        while let _target = target {
            _target.prepareEventContext(context: event.context)
            parents.append(_target)
            target = _target.parent
        }
        
        // 先走自上而下的拦截逻辑
        for node in parents.reversed() {
            if node.interceptEvent(event: event, callback: callback) {
                return true
            }
        }
        
        // 再走自下而上的处理逻辑
        for node in parents {
            if node.handleEvent(event: event, callback: callback) {
                return true
            }
        }
        
        callback.callbackNoHandler(data: nil)
        return true
    }
    
}
