//
//  UIView+KeyboardLayoutGuide.swift
//  SKUIKit
//
//  Created by liujinwei on 2023/1/29.
//  

import Foundation
import SKFoundation
import LarkKeyboardKit

extension UIView {
    
    private enum AssociatedKeys {
        static var keyboardLayoutGuide = "customKeyboardLayoutGuide"
    }
    
    public var skKeyboardLayoutGuide: SKKeyboardLayoutGuide {
        if let obj = objc_getAssociatedObject(self, &AssociatedKeys.keyboardLayoutGuide) as? SKKeyboardLayoutGuide {
            return obj
        }
        let layoutGuide = SKKeyboardLayoutGuide()
        self.addLayoutGuide(layoutGuide)
        layoutGuide.setUp()
        objc_setAssociatedObject(self, &AssociatedKeys.keyboardLayoutGuide, layoutGuide, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return layoutGuide
    }
}

public class SKKeyboardLayoutGuide: UILayoutGuide {
    
    private var keyboard: Keyboard = Keyboard()
    
    private var minKeyboardHeight: CGFloat {
        return owningView?.safeAreaInsets.bottom ?? 20
    }
    
    internal var callbacks: [String: KeyboardCallback?] = [:]
    
    public typealias KeyboardCallback = (_ isShow: Bool, _ height: CGFloat, _ options: Keyboard.KeyboardOptions) -> Void
    
    public func on(identifier: String, do callback: KeyboardCallback?) {
        callbacks[identifier] = callback
    }
    
    func setUp() {
        guard let view = owningView else { return }
        topAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        if #available(iOS 15, *) {
            view.keyboardLayoutGuide.followsUndockedKeyboard = true
            bottomAnchor.constraint(greaterThanOrEqualTo: view.keyboardLayoutGuide.topAnchor).isActive = true
        }
        keyboard.on(events: [.willShow, .willChangeFrame, .willHide, .didShow, .didChangeFrame, .didHide, .didChangeInputMode]) { [weak self] (options) in
            if options.event == .didChangeInputMode {
                //切换输入法，例如切到搜狗输入法，键盘高度可能发生变化，但不会有change、show、hide事件，使用didChangeInputMode获取时机
                if #available(iOS 15.0, *) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
                        self?.animate(with: options)
                    }
                }
            } else {
                self?.animate(with: options)
            }
        }
        keyboard.start()
    }
    
    deinit {
        keyboard.stop()
    }
    
    private func animate(with options: Keyboard.KeyboardOptions) {
        guard let height = self.keyboardHeightInView(options) else { return }
        let isShow = self.keyboardShowState(keyboardHeight: height, with: options)
        self.callbacks.values.forEach { callback in
            callback?(isShow, height, options)
        }
        guard self.topConstraint?.constant != height else { return }
        self.topConstraint?.constant = -height
        if let owningView = self.owningView,
            isVisible(view: owningView) {
            let animationCurve = UIView.AnimationOptions(rawValue: UInt(options.animationCurve.rawValue))
            UIView.animate(withDuration: options.animationDuration,
                           delay: 0,
                           options: animationCurve,
                           animations: { self.owningView?.layoutIfNeeded() })
        } else {
            UIView.performWithoutAnimation {
                self.owningView?.layoutIfNeeded()
            }
        }
    }
    
    private func keyboardHeightInView(_ options: Keyboard.KeyboardOptions) -> CGFloat? {
        guard let view = self.owningView else {
            assertionFailure("owningView is nil")
            return nil
        }
        var keyboardHeight: CGFloat = -1
        if #available(iOS 15, *) {
            let layoutFrame = view.keyboardLayoutGuide.layoutFrame
            if layoutFrame.minY == .zero {
                return nil
            }
            keyboardHeight = view.frame.height - layoutFrame.minY
        }
        
        keyboardHeight = fixKeyboardHeight(keyboardHeight)
        
        if options.displayType == .floating {
            keyboardHeight = view.safeAreaInsets.bottom
        } else if keyboardHeight <= minKeyboardHeight {
            //取到的键盘高度小于安全区域，使用option.endFrame兜底
            if options.endFrame == .zero {
                return .zero
            }
            let pointInKeyboardWindow = CGPoint(x: 0, y: options.endFrame.minY)
            var pointInWindow = pointInKeyboardWindow
            if let window = view.window,
               window.bounds.height < SKDisplay.mainScreenBounds.height {
                let zeroPointInScreen = window.convert(CGPoint.zero, to: UIScreen.main.coordinateSpace)
                pointInWindow.y = options.endFrame.minY - zeroPointInScreen.y
            }
            let pointInView = view.convert(pointInWindow, from: nil)
            keyboardHeight = view.frame.height - pointInView.y
        } else {
            let keyboardOriginPoint = CGPoint(x: 0, y: view.frame.height - keyboardHeight)
            if view.convert(keyboardOriginPoint, to: UIScreen.main.coordinateSpace).y < SKDisplay.mainScreenBounds.height / 4 {
                //得到的的layoutFrame顶部在屏幕上半1/4区域，说明产生异常，进行屏蔽
                return nil
            }
        }
        return keyboardHeight > 0 ? keyboardHeight : 0
    }
    
    private func fixKeyboardHeight(_ height: CGFloat) -> CGFloat {
        if #available(iOS 16.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            if scenes.count > 1 {
                var windowHeight: CGFloat = .zero
                for scene in scenes {
                    let sceneHeight = scene.rootWindow()?.bounds.height ?? .zero
                    if windowHeight != .zero, windowHeight != sceneHeight {
                        //iOS 16台前调度+分屏，多个scene的高度不一致时，layoutFrame传递的值不正确，需要option.endFrame兜底
                        return minKeyboardHeight
                    }
                    windowHeight = sceneHeight
                }
            }
        }
        return height
    }
    
    private func keyboardShowState(keyboardHeight: CGFloat, with options: Keyboard.KeyboardOptions) -> Bool {
        if options.displayType == .floating {
            if options.event == .didChangeFrame && options.endFrame == .zero { return false }
        } else {
            if keyboardHeight <= minKeyboardHeight { return false }
        }
        return true
    }
    
    private var topConstraint: NSLayoutConstraint? {
        return owningView?.constraints.first {
            $0.firstItem as? UILayoutGuide == self && $0.firstAttribute == .top
        }
    }
    
    private func isVisible(view: UIView) -> Bool {
        func isVisible(view: UIView, inView: UIView?) -> Bool {
            if view.isHidden || view.alpha == 0 {
                return false
            }
            guard let inView = inView else {
                return view is UIWindow
            }
            if inView.isHidden || inView.alpha == 0 {
                return false
            }

            let viewFrame = inView.convert(view.bounds, from: view)
            if viewFrame.intersects(inView.bounds) {
                return isVisible(view: inView, inView: inView.superview)
            }
            return false
        }
        return isVisible(view: view, inView: view.superview)
    }
    
}
