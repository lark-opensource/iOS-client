//
//  BindEnableObject.swift
//  LarkUIExtensionWrapper
//
//  Created by 李晨 on 2020/3/14.
//

import Foundation

public protocol BindEnableObject: AnyObject {
    /// 在环境发生变化，需要全局刷新的时候会调用此方法判断是否需要刷新该对象
    /// 如果自定义此方法，返回 false，则需要在合适的时机判断 BindEnableObject.ueDirtyTag 进行刷新
    func needUpdateByBindValue() -> Bool
}

extension NSObject: BindEnableObject {}

extension BindEnableObject {
    public func needUpdateByBindValue() -> Bool {
        return true
    }
}

private let customKeyPrefix = "lark.ui.extension.custom.block."

private let queueUUID = DispatchSpecificKey<String>()

extension LarkUIExtensionWrapper where BaseType: BindEnableObject {

    /// 根据 keyPath 添加绑定属性，调用此接口会立刻进行一次赋值
    /// - Parameters:
    ///   - keyPath: 需要更新 keyPath
    ///   - value: 需要被更新的 value
    @discardableResult
    public func bind<Value>(
        keyPath: ReferenceWritableKeyPath<BaseType, Value>,
        value: @escaping @autoclosure () -> Value) -> LarkUIExtensionWrapper<BaseType> {
        assert(ThemeManager.didSetup, "please setup by ThemeManager.setupIfNeeded()")
        PropertyStore.shared.store(
            object: self.base,
            keyPath: keyPath,
            value: value)
        return self
    }

    /// 根据自定义 key 添加绑定属性，调用此接口会立刻进行一次赋值
    /// - Parameters:
    ///   - identifier: 此次绑定的 id, 可以根据此 id 进行更新和删除，如果不设置，会自动生成一个随机 id
    ///   - updateQueue: 可以指定此次绑定的更新队列
    ///   - block: bind 更新闭包
    @discardableResult
    public func bind(
        identifier: String = UUID().uuidString,
        updateQueue: DispatchQueue? = nil,
        block: @escaping (BaseType) -> Void) -> LarkUIExtensionWrapper<BaseType> {
        assert(ThemeManager.didSetup, "please setup by ThemeManager.setupIfNeeded()")
        let fullIdentifier = customKeyPrefix + identifier
        setupQueueUUID(queue: updateQueue)
        PropertyStore.shared.store(
            object: self.base,
            key: fullIdentifier) { (object) in
                if let queue = updateQueue,
                    queue.getSpecific(key: queueUUID) != DispatchQueue.getSpecific(key: queueUUID) {
                    queue.async {
                        block(object)
                    }
                } else {
                    block(object)
                }
        }

        return self
    }

    /// 解绑对应 keyPath 自动更新
    /// - Parameter keyPath: 需要解绑的 keyPath
    @discardableResult
    public func unbind<Value>(keyPath: ReferenceWritableKeyPath<BaseType, Value>) -> LarkUIExtensionWrapper<BaseType> {
        PropertyStore.shared.delete(
            object: self.base,
            keyPath: keyPath
        )
        return self
    }

    /// 解绑自定义 key 自动更新
    /// - Parameter identifier: 此次解绑的 id
    @discardableResult
    public func unbind(identifier: String) -> LarkUIExtensionWrapper<BaseType> {
        let fullIdentifier = customKeyPrefix + identifier
        PropertyStore.shared.delete(object: self.base, key: fullIdentifier)
        return self
    }

    func setupQueueUUID(queue: DispatchQueue?) {
        guard let queue = queue else { return }
        if queue.getSpecific(key: queueUUID) == nil {
            queue.setSpecific(key: queueUUID, value: UUID().uuidString)
        }
    }
}
