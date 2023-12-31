//
//  KeyboardLayoutGuide.swift
//  KeyboardKit
//
//  Created by 李晨 on 2019/10/17.
//

import UIKit
import Foundation
import RxSwift

extension UIView {
    private enum AssociatedKeys {
        static var keyboardLayoutGuide = "kk_keyboardLayoutGuide"
    }

    /// A layout guide representing the inset for the keyboard.
    /// Use this layout guide’s top anchor to create constraints pinning to the top of the keyboard.
    public var lkKeyboardLayoutGuide: KeyboardLayoutGuide {
        if let obj = objc_getAssociatedObject(self, &AssociatedKeys.keyboardLayoutGuide) as? KeyboardLayoutGuide {
            return obj
        }
        let new = KeyboardLayoutGuide()
        addLayoutGuide(new)
        new.setUp()
        objc_setAssociatedObject(
            self,
            &AssociatedKeys.keyboardLayoutGuide,
            new as Any,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return new
    }
}

open class KeyboardLayoutGuide: UILayoutGuide {

    /// use safe area bottom layout, default is false
    public var respectSafeArea: Bool = false {
        didSet {
            updateButtomAnchor()
        }
    }

    /// update uses safe area
    /// - Parameter respectSafeArea: value for use safe area
    public func update(respectSafeArea: Bool) -> KeyboardLayoutGuide {
        self.respectSafeArea = respectSafeArea
        return self
    }

    private var bottomConstraint: NSLayoutConstraint?
    private var disposeBag = DisposeBag()

    func setUp() {
        guard let view = owningView else { return }
        NSLayoutConstraint.activate(
            [
                heightAnchor.constraint(equalToConstant: KeyboardKit.shared.currentHeight),
                leftAnchor.constraint(equalTo: view.leftAnchor),
                rightAnchor.constraint(equalTo: view.rightAnchor)
            ]
        )
        updateButtomAnchor()

        self.disposeBag = DisposeBag()
        KeyboardKit.shared.keyboardHeightChange(for: view)
            .drive(onNext: { [weak self] (keyboardHeight) in
                var keyboardHeight = keyboardHeight
                guard let self = self else { return }
                if #available(iOS 11.0, *),
                    self.respectSafeArea,
                    keyboardHeight > 0,
                    let bottom = self.owningView?.safeAreaInsets.bottom {
                    keyboardHeight -= bottom
                }
                self.heightConstraint?.constant = keyboardHeight
                self.animate()
            }).disposed(by: self.disposeBag)
    }

    private func updateButtomAnchor() {
        if let bottomConstraint = bottomConstraint {
            bottomConstraint.isActive = false
        }

        guard let view = owningView else { return }

        let viewBottomAnchor: NSLayoutYAxisAnchor
        if #available(iOS 11.0, *), respectSafeArea {
            viewBottomAnchor = view.safeAreaLayoutGuide.bottomAnchor
        } else {
            viewBottomAnchor = view.bottomAnchor
        }

        bottomConstraint = bottomAnchor.constraint(equalTo: viewBottomAnchor)
        bottomConstraint?.isActive = true
    }

    private func animate() {
        if let owningView = self.owningView,
            isVisible(view: owningView) {
            self.owningView?.layoutIfNeeded()
        } else {
            UIView.performWithoutAnimation {
                self.owningView?.layoutIfNeeded()
            }
        }
    }

    private var heightConstraint: NSLayoutConstraint? {
        return owningView?.constraints.first {
            $0.firstItem as? UILayoutGuide == self && $0.firstAttribute == .height
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
