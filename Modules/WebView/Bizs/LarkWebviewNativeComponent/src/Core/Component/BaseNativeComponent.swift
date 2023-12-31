//
//  BaseNativeComponent.swift
//  LarkWebviewNativeComponent
//
//  Created by tefeng liu on 2020/10/30.
//

import Foundation
import LarkWebViewContainer

public final class WeakReferrence {
    public weak var webview: LarkWebView?
}

public protocol NativeComponentProperty {
    /// 标签名
    static var tagName: String { get }

    /// 唯一标示id
    var id: String { get set }

    /// 弱引用
    var weakRef: WeakReferrence { get }
}

public protocol NativeComponetEventAble {

    /// 即将准备插入
    /// - Parameter params: 前端回调的参数的参数
    func willInsertComponent(params: [String: Any])

    /// 插入成功后的回调
    /// - Parameter params: 与will中的参数一致
    func didInsertComponent(params: [String: Any])

    /// 更新属性
    /// - Parameter pramss: 参数
    func updateCompoent(params: [String: Any])

    /// 即将移除
    func willBeRemovedComponent(params: [String: Any])

    /// naitve -> h5的通信
    func fireEvent(name: String, params: [String: Any])
}

public protocol NativeComponentAble: class, NativeComponentProperty, NativeComponetEventAble {
    init()

    var nativeView: UIView { get }
}

// MARK: NativeComponentProperty 默认实现
private var kId: Void?
private var kWeakRef: Void?
public extension NativeComponentProperty {
    var id: String {
        get {
            return objc_getAssociatedObject(self, &kId) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, &kId, newValue ?? "", .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    var weakRef: WeakReferrence {
        if let ref = objc_getAssociatedObject(self, &kWeakRef) as? WeakReferrence {
            return ref
        } else {
            let ref = WeakReferrence()
            objc_setAssociatedObject(self, &kWeakRef, ref, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return ref
        }
    }
}

// MARK: NativeComponetEventAble 默认实现
public extension NativeComponetEventAble where Self: NativeComponentProperty {
    func fireEvent(name: String, params: [String: Any]) {
        weakRef.webview?.componetBridge.fireEvent(event: name, params: params, id: id)
    }
}
