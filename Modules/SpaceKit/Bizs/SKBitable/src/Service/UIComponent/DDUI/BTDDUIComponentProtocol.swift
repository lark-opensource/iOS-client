//
//  BTDDUIWidgetProtocol.swift
//  SKBitable
//
//  Created by X-MAN on 2023/4/12.
//

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface

fileprivate var contextKey: String = "BTDDUIComponentProtocol.contextKey"
fileprivate var onMountCallbackIdKey: String = "onMountCallbackId"
fileprivate var onUnmountCallbackIdKey: String = "onUnmountCallbackIdKey"
fileprivate var onUnmountBlockKey: String = "onUnmountBlockKey"



protocol BDTTDUIComponentStateDelegate: AnyObject {
    func onMounted(_ component: any BTDDUIComponentProtocol)
    func onUnmounted(_ component: any BTDDUIComponentProtocol)
}

class BTDDUIWeakObjectWrapper {
    weak var value: AnyObject?
    init(value: AnyObject?) {
        self.value = value
    }
}

protocol BTDDUIComponentProtocol: AnyObject {
    associatedtype UIModel: BTDDUIPlayload
    // 数据解析
    static func convert(from payload: Any?) throws -> UIModel
    // component 加载、设置初始数据
    func mount(with model: UIModel) throws
    // component更新数据
    func setData(with model: UIModel) throws
    // 卸载component
    func unmount()
}


extension BTDDUIComponentProtocol {
    
    var unmountBlock: (() -> Void)? {
        set {
            objc_setAssociatedObject(self, &onUnmountBlockKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &onUnmountBlockKey) as? () -> Void
        }
    }
    
    var context: BTDDUIContext? {
        set {
            objc_setAssociatedObject(self, &contextKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &contextKey) as? BTDDUIContext
        }
    }
    
    var onMountCallbackId: String? {
        set {
            objc_setAssociatedObject(self, &onMountCallbackIdKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &onMountCallbackIdKey) as? String
        }
    }
    
    var onUnmountCallbackId: String? {
        set {
            objc_setAssociatedObject(self, &onUnmountCallbackIdKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &onUnmountCallbackIdKey) as? String
        }
    }
    
    /// 事件回调 component需要给前端的回调直接调这个方法
    func emitEvent(callbackId: String, args: [String: AnyHashable]) {
        context?.emitEvent(callbackId, args: args)
    }
    /// 组件已经加载事件回调 给前端
    func onMounted() {
        guard let callbackId = onMountCallbackId else {
            DocsLogger.btError("[BTDDUIComponentProtocol] can not find callbackId ")
            return
        }
        emitEvent(callbackId: callbackId, args: [:])
    }
    /// 组件消失回调给前端
    func onUnmounted() {
        guard let callbackId = onUnmountCallbackId else {
            DocsLogger.btError("[BTDDUIComponentProtocol] can not find callbackId ")
            return
        }
        emitEvent(callbackId: callbackId, args: [:])
        unmountBlock?()
    }
    
}
