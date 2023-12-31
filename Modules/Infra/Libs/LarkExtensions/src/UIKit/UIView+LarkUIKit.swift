//
//  UIView+LarkUIKit.swift
//  LarkUIKit
//
//  Created by 李耀忠 on 2016/12/15.
//  Copyright © 2016年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkCompatible
import SnapKit
import UIKit
import UniverseDesignColor
import UniverseDesignTheme

// UIView 的父类 UIResponder 已经实现了该协议，预计 Swift6.0 会解决这个警告；
// 暂时先注释掉
//
// extension UIView: LarkUIKitExtensionCompatible {}

public extension LarkUIKitExtension where BaseType: UIView {
    func screenshot() -> UIImage? {
        let transform = self.base.transform
        self.base.transform = .identity
        var screenshot: UIImage?
        UIGraphicsBeginImageContextWithOptions(self.base.frame.size, false, UIScreen.main.scale)
        if let context = UIGraphicsGetCurrentContext() {
            self.base.layer.render(in: context)
            screenshot = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        self.base.transform = transform
        return screenshot
    }

    func screenshot(maxLength: CGFloat) -> UIImage? {
        var scaleFactor = min(1, max(0, maxLength / max(base.bounds.width, base.bounds.height)))
        let transform = self.base.transform
        self.base.transform = .identity
        var screenshot: UIImage?
        UIGraphicsBeginImageContextWithOptions(self.base.frame.size, false, UIScreen.main.scale * scaleFactor)
        if let context = UIGraphicsGetCurrentContext() {
            self.base.layer.render(in: context)
            screenshot = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        self.base.transform = transform
        return screenshot
    }
}

// MARK: - 添加手势的便利方法

public extension LarkUIKitExtension where BaseType: UIView {
    @discardableResult
    func addTapGestureRecognizer(action: Selector,
                                 target: AnyObject? = nil,
                                 touchNumber: Int = 1) -> UITapGestureRecognizer {
        let tap = UITapGestureRecognizer(target: target ?? self.base, action: action)
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = touchNumber
        self.base.isUserInteractionEnabled = true
        self.base.addGestureRecognizer(tap)
        return tap
    }

    @discardableResult
    func addLongPressGestureRecognizer(action: Selector,
                                       duration: CFTimeInterval,
                                       target: AnyObject? = nil) -> UILongPressGestureRecognizer {
        let longPress = UILongPressGestureRecognizer(target: target ?? self.base, action: action)
        longPress.minimumPressDuration = duration

        self.base.addGestureRecognizer(longPress)
        return longPress
    }

    @discardableResult
    func addPanGestureRecognizer(action: Selector, target: AnyObject? = nil) -> UIPanGestureRecognizer {
        let panGesture = UIPanGestureRecognizer(target: target ?? self.base, action: action)
        self.base.isUserInteractionEnabled = true
        self.base.addGestureRecognizer(panGesture)
        return panGesture
    }
}

public extension LarkUIKitExtension where BaseType: UIView {
    func addTopBorder(
        leading: ConstraintRelatableTarget = 0,
        trailing: ConstraintRelatableTarget = 0,
        color: UIColor = UIColor.ud.commonTableSeparatorColor
    ) {
        let borderView = UIView(frame: CGRect.zero)
        self.base.addSubview(borderView)
        borderView.backgroundColor = color
        borderView.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.left.equalTo(leading).priority(.low)
            make.right.equalTo(trailing).priority(.low)
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    func addleftBorder(
        top: ConstraintRelatableTarget = 0,
        bottom: ConstraintRelatableTarget = 0,
        color: UIColor = UIColor.ud.commonTableSeparatorColor
    ) {
        let borderView = UIView(frame: CGRect.zero)
        self.base.addSubview(borderView)
        borderView.backgroundColor = color
        borderView.snp.makeConstraints { make in
            make.left.equalTo(0)
            make.top.equalTo(top).priority(.low)
            make.bottom.equalTo(bottom).priority(.low)
            make.width.equalTo(1 / UIScreen.main.scale)
        }
    }

    func addRightBorder(
        top: ConstraintRelatableTarget = 0,
        bottom: ConstraintRelatableTarget = 0,
        color: UIColor = UIColor.ud.commonTableSeparatorColor
    ) {
        let borderView = UIView(frame: CGRect.zero)
        self.base.addSubview(borderView)
        borderView.backgroundColor = color
        borderView.snp.makeConstraints { make in
            make.right.equalTo(0)
            make.top.equalTo(top).priority(.low)
            make.bottom.equalTo(bottom).priority(.low)
            make.width.equalTo(1 / UIScreen.main.scale)
        }
    }

    @discardableResult
    func addBottomBorder(
        leading: ConstraintRelatableTarget = 0,
        trailing: ConstraintRelatableTarget = 0,
        color: UIColor = UIColor.ud.commonTableSeparatorColor
    ) -> UIView {
        let borderView = UIView(frame: CGRect.zero)
        self.base.addSubview(borderView)
        borderView.backgroundColor = color
        borderView.snp.makeConstraints { make in
            make.bottom.equalTo(0)
            make.left.equalTo(leading).priority(.low)
            make.right.equalTo(trailing).priority(.low)
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        return borderView
    }

    // 使用lk.isHidden会把top约束变成0
    var isHidden: Bool {
        get { base.isHidden }
        set {
            if isHidden == newValue {
                return
            }
            self.base.isHidden = newValue

            if newValue {
                self.base.superview?.constraints.forEach { constraint in
                    if constraint.firstItem as? UIView == self.base {
                        switch constraint.firstAttribute {
                        case .top:
                            constraint.constant = 0
                        default: break
                        }
                    }
                }
                self.base.constraints.forEach({ constraint in
                    if constraint.firstAttribute == .height {
                        constraint.constant = 0
                    }
                    switch constraint.firstAttribute {
                    case .top, .height:
                        constraint.constant = 0
                    default: break
                    }
                })
            }
        }
    }

    func addRotateAnimation(duration: CFTimeInterval = 1) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(CGFloat.pi * 2)
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.duration = duration
        rotateAnimation.repeatCount = Float.infinity
        self.base.layer.add(rotateAnimation, forKey: "lu.rotateAnimation")
    }

    func removeRotateAnimation() {
        self.base.layer.removeAllAnimations()
    }

    func harder() {
        self.base.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        self.base.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.base.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        self.base.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }

    func softer() {
        self.base.setContentHuggingPriority(.defaultLow, for: .horizontal)
        self.base.setContentHuggingPriority(.defaultLow, for: .vertical)
        self.base.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.base.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    @discardableResult
    func blink(color: UIColor,
               borderColor: UIColor,
               rectInset: UIEdgeInsets = UIEdgeInsets.zero,
               duration: TimeInterval = 0.5,
               complete: (() -> Void)? = nil) -> UIView {
        let view = UIView()
        var frame = self.base.frame
        frame.origin = .zero
        frame = frame.inset(by: rectInset)
        view.frame = frame
        view.backgroundColor = color
        view.layer.borderWidth = 1 / UIScreen.main.scale
        view.ud.setLayerBorderColor(borderColor)
        view.alpha = 1
        self.base.insertSubview(view, at: 0)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        UIView.animateKeyframes(withDuration: duration, delay: 0, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5, animations: {
                view.alpha = 1
            })
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5, animations: {
                view.alpha = 0
            })
        }, completion: { _ in
            complete?()
            view.removeFromSuperview()
        })
        return view
    }

    // 指定UIView的角为圆角
    func addCorner(roundingCorners: UIRectCorner, cornerSize: CGSize) {
        let shapeLayer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: self.base.bounds,
                                byRoundingCorners: roundingCorners,
                                cornerRadii: cornerSize)
        shapeLayer.path = path.cgPath
        shapeLayer.frame = self.base.bounds
        self.base.layer.masksToBounds = true
        self.base.layer.mask = shapeLayer
    }

    @available(iOS 11.0, *)
    func addCorner(corners: CACornerMask, cornerSize: CGSize) {
        self.base.layer.cornerRadius = cornerSize.width
        self.base.layer.masksToBounds = true
        self.base.layer.maskedCorners = corners
    }
}

public extension LarkUIKitExtension where BaseType: UIView {
    /// 返回当前 UIView 上的第一响应者
    ///
    /// - Returns: first reponder
    func firstResponder() -> UIView? {
        if self.base.isFirstResponder { return self.base }
        for subview in self.base.subviews {
            if let firstResponder = subview.lu.firstResponder() {
                return firstResponder
            }
        }
        return nil
    }
}
