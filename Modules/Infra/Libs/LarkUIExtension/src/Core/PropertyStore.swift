//
//  PropertyStore.swift
//  LarkUIExtensionWrapper
//
//  Created by 李晨 on 2020/3/10.
//

import UIKit
import Foundation

public final class PropertyStore {
    public static let shared: PropertyStore = {
        /// swift 单例线程安全，进行 swizzing
        Swizzing.uiExtensionSwizzleMethod()
        return PropertyStore()
    }()

    private var store = NSMapTable<AnyObject, PropertySet>(
        keyOptions: .weakMemory,
        valueOptions: .strongMemory
    )

    private var updateObserver: NSObjectProtocol?

    init() {
        updateObserver = NotificationCenter.default.addObserver(
            forName: ThemeManager.ThemeDidChange,
            object: nil,
            queue: OperationQueue.main) { [weak self] (_) in
                self?.updateAppearance()
        }
    }

    /// 存储 object 需要被更新的自定义 key 以及更新 handler
    /// - Parameters:
    ///   - object: 需要被更新的 object
    ///   - key: 自定义更新 key
    ///   - handler: 自定义更新闭包
    public func store<Object: BindEnableObject>(
        object: Object,
        key: PropertyKey,
        handler: @escaping PropertyHandler<Object>
    ) {
        doInMainThread {
            let propertySet = self.propertySet(object: object)
            propertySet.value[key] = BlockObject({ [weak object] in
                if let object = object {
                    handler(object)
                }
            })
        }
        handler(object)
    }

    /// 存储 object 需要被更新的 keyPath 以及更新闭包
    /// - Parameters:
    ///   - object: 需要被更新的 object
    ///   - keyPath: 需要被更新的 keyPath
    ///   - value: 自定义更新闭包
    public func store<Object: BindEnableObject, Value>(
        object: Object,
        keyPath: ReferenceWritableKeyPath<Object, Value>,
        value: @escaping () -> Value
    ) {
        doInMainThread {
            let propertySet = self.propertySet(object: object)
            propertySet.keyPath[keyPath] = BlockObject({ [weak object] in
                object?[keyPath: keyPath] = value()
            })
        }
        object[keyPath: keyPath] = value()
    }

    /// 删除 key 对应属性
    public func delete<Object: BindEnableObject>(
        object: Object,
        key: PropertyKey
    ) {
        doInMainThread {
            let propertySet = self.propertySet(object: object)
            propertySet.value[key] = nil
        }
    }

    /// 删除 keyPath 对应属性
    public func delete<Object: BindEnableObject, Value>(
        object: Object,
        keyPath: ReferenceWritableKeyPath<Object, Value>
    ) {
        doInMainThread {
            let propertySet = self.propertySet(object: object)
            propertySet.keyPath[keyPath] = nil
        }
    }

    private func updateAppearance() {
        let animationDuration = UIExtension.animationDuration
        if animationDuration > 0 && UIView.areAnimationsEnabled {
            var snapshotViews: [UIView] = []
            let windows = UIApplication.shared.windows
            windows.forEach { view in
                guard let snapshotView = view.snapshotView(afterScreenUpdates: false) else {
                    return
                }
                view.addSubview(snapshotView)
                snapshotViews.append(snapshotView)
            }

            self.updateAllObjectProperty()

            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: animationDuration, delay: 0, options: [], animations: {
                snapshotViews.forEach { $0.alpha = 0 }
            }) { _ in
                snapshotViews.forEach { $0.removeFromSuperview() }
            }
        }
        else {
            self.updateAllObjectProperty()
        }
    }

    private func updateAllObjectProperty() {
        NotificationCenter.default.post(
            name: UIExtension.UIWillUpdate,
            object: nil
        )
        for key in self.store.keyEnumerator() {
            if let object = key as? NSObject {
                self.updateProperty(object: object)
            }
        }
        NotificationCenter.default.post(
            name: UIExtension.UIDidUpdate,
            object: nil
        )
    }

    /// 刷新某一个 BindEnableObject 对象
    public func updateProperty(object: BindEnableObject) {
        guard object.needUpdateByBindValue() else {
            object.ueDirtyTag = true
            return
        }
        let propertySet = self.store.object(forKey: object) ?? PropertySet()

        /// 更新所有 keyPath 属性
        propertySet.keyPath.values.forEach { (blockValue) in
            blockValue.block()
        }

        /// 更新所有自定义 key 属性
        propertySet.value.values.forEach { (blockValue) in
            blockValue.block()
        }

        object.ueDirtyTag = false
    }

    private func propertySet(object: BindEnableObject) -> PropertySet {
        var propertySet: PropertySet
        if let set = self.store.object(forKey: object) {
            propertySet = set
        } else {
            propertySet = PropertySet()
            self.store.setObject(propertySet, forKey: object)
        }
        return propertySet
    }

    private func doInMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
