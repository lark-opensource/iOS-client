//
//  WindowSceneLayoutContextObservable.swift
//  ByteViewUI
//
//  Created by kiri on 2023/10/31.
//

import Foundation
import ByteViewCommon

extension VCExtension where BaseType: UIView {
    public var windowSceneLayoutContext: WindowSceneLayoutContext? {
        assertMain()
        if #available(iOS 13.0, *), VCScene.supportsMultipleScenes {
            if let ws = self.compatibleWindow?.windowScene {
                return WindowSceneLayoutContext(interfaceOrientation: ws.interfaceOrientation, traitCollection: ws.traitCollection, coordinateSpace: ws.coordinateSpace)
            }
        } else if let ow = UIApplication.shared.delegate?.window, let w = ow {
            return WindowSceneLayoutContext(interfaceOrientation: UIApplication.shared.statusBarOrientation, traitCollection: w.traitCollection, coordinateSpace: w.coordinateSpace)
        }
        return nil
    }

    public var windowSceneLayoutContextObservable: WindowSceneLayoutContextObservable {
        assertMain()
        if let obj = objc_getAssociatedObject(base, &WindowSceneLayoutContextObservable.associatedKey) as? WindowSceneLayoutContextObservable {
            return obj
        }
        let obj = WindowSceneLayoutContextObservable(view: self.base)
        objc_setAssociatedObject(base, &WindowSceneLayoutContextObservable.associatedKey, obj, .OBJC_ASSOCIATION_RETAIN)
        return obj
    }

    fileprivate var compatibleWindow: UIWindow? {
        if let w = base as? UIWindow {
            return w
        }
        return base.window
    }
}

public final class WindowSceneLayoutContextObservable {
    fileprivate static var associatedKey = 0

    private weak var view: UIView?
    private let observers = BlockListeners<(WindowSceneLayoutContext?, WindowSceneLayoutContext)>()
    fileprivate init(view: UIView) {
        self.view = view
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateWindowScene(_:)), name: VCNotification.didUpdateWindowSceneNotification, object: nil)
    }

    public func addObserver(_ observer: AnyObject, handler: @escaping (WindowSceneLayoutContext?, WindowSceneLayoutContext) -> Void) {
        observers.addListener(observer) {
            handler($0.0, $0.1)
        }
    }

    @objc private func didUpdateWindowScene(_ notification: Notification) {
        guard let window = self.view?.vc.compatibleWindow, let userInfo = notification.userInfo,
              let context = userInfo[VCNotification.layoutContextKey] as? WindowSceneLayoutContext else {
            return
        }
        let previousContext = userInfo[VCNotification.previousLayoutContextKey] as? WindowSceneLayoutContext
        if #available(iOS 13.0, *) {
            if let ws = notification.object as? UIWindowScene {
                if window.windowScene == ws {
                    observers.send((previousContext, context))
                }
            } else if let w = notification.object as? UIWindow {
                if window == w || window.windowScene == w.windowScene {
                    observers.send((previousContext, context))
                }
            } else {
                observers.send((previousContext, context))
            }
        } else {
            observers.send((previousContext, context))
        }
    }
}
