//
//  FrameObserver.swift
//  FigmaKit
//
//  Created by Hayden Wang on 2021/9/11.
//

import UIKit
import Foundation

// MARK: - Observer

final class LayerObserver: NSObject {

    var onFrameChange: [String: (priority: Int, setter: () -> Void)] = [:]

    var kvoToken: NSKeyValueObservation?

    weak var layer: CALayer? {
        didSet {
            observeFrameChange()
        }
    }

    private func observeFrameChange() {
        if #available(iOS 13, *) {
            // iOS13 以上系统用 KVO 方式监听 frame 变化
            kvoToken = layer?.observe(\.bounds, options: .new, changeHandler: { [weak self] (_, _) in
                self?.executeFrameChangeCallbacks()
            })
        } else {
            // iOS13 以下系统通过 hook layoutSublayers 的方式监听 frame 变化
            // 在 iOS13 以下，这种方式 hook 会导致崩溃，原因是监听者（LayerObserver）
            // 是通过 associatedObject 挂在被监听者（Layer）上的，释放时机在 Layer
            // 之后，Layer 释放时 KVO 未移除会导致崩溃。
            CALayer.hookLayoutSublayersIfNeeded()
        }
    }

    fileprivate func observedDidLayoutSublayers() {
        executeFrameChangeCallbacks()
    }

    private func executeFrameChangeCallbacks() {
        onFrameChange.values
            .sorted(by: { $0.priority < $1.priority })
            .forEach({ $0.setter() })
    }
}

// MARK: - Associated object

extension CALayer {

    private struct AssociatedKeys {
        static var propertyObserverKey = "LayerPropertyObserver"
    }

    // swiftlint:disable all
    var propertyObserver: LayerObserver? {
        get {
            objc_getAssociatedObject(
                self,
                &AssociatedKeys.propertyObserverKey
            ) as? LayerObserver
        }
        set {
            guard newValue != propertyObserver else { return }
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.propertyObserverKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN
            )
        }
    }
    // swiftlint:enable all
}

// MARK: - Hook dealloc

extension DispatchQueue {

    private static var onceTokenTracker: [String] = []
    /// 保证整个生命周期只执行一次
    ///
    /// - Parameters:
    ///   - token: token
    ///   - block: 执行的代码块
    static func dispatchOnce(_ token: String, block: () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        if onceTokenTracker.contains(token) {
            return
        }
        onceTokenTracker.append(token)
        block()
    }
}

extension CALayer {

    private static let onceToken = UUID().uuidString

    static func hookLayoutSublayersIfNeeded() {
        guard self == CALayer.self else { return }
        DispatchQueue.dispatchOnce(onceToken) {
            let originalSelector = NSSelectorFromString("layoutSublayers")
            let swizzledSelector = NSSelectorFromString("swizzle_layoutSublayers")
            if let originalMethod = class_getInstanceMethod(self, originalSelector),
               let swizzledMethod = class_getInstanceMethod(self, swizzledSelector) {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }

    @objc
    func swizzle_layoutSublayers() {
        if let observer = propertyObserver {
            observer.observedDidLayoutSublayers()
        }
        self.swizzle_layoutSublayers()
    }
}
