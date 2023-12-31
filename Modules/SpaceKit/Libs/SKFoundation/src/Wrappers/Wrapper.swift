//
//  Wrapper.swift
//  SpaceKit
//
//  Created by huahuahu on 2019/1/20.
//

import Foundation

/// 用于数据绑定的类
public final class ObserableWrapper<T> {
    public typealias Listenr = (T) -> Void

    private var observers: NSHashTable<AnyObject>
    private var managerKey: Void?

    /// 真正存储的值
    public var value: T {
        didSet {
            observers.allObjects.forEach { (observer) in
                let block = objc_getAssociatedObject(observer, &managerKey)
                if let block1 = block as? Listenr {
                    block1(value)
                }
            }
        }
    }

    /// 初始化方法
    ///
    /// - Parameter value: 用来被绑定的value
    public init(_ value: T) {
        self.value = value
        observers = NSHashTable<AnyObject>.weakObjects()
    }

    /// 添加观察者。target在销毁时，会自动移除观察，不会有内存泄漏。
    ///
    /// - Parameters:
    ///   - target: 观察者，变化时，会通知到它
    ///   - block: 发生变化时，需要执行的操作。block为nil，取消绑定
    public func bind(target: AnyObject, block: Listenr?) {
        observers.add(target)
        objc_setAssociatedObject(target, &managerKey, block, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        block?(value)
        if block == nil {
            observers.remove(target)
        }
    }
}

public final class Weak<T: AnyObject> {
    public weak var value: T?
    public init(_ value: T) {
        self.value = value
    }
}

public final class Strong<T: Any> {
    public var value: T
    public init(_ value: T) {
        self.value = value
    }
}
