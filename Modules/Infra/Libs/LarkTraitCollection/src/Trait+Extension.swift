//
//  UIView+Extension.swift
//  LarkTraitCollection
//
//  Created by 李晨 on 2020/5/25.
//

import UIKit
import Foundation

/// 这里只暴露 UIWindow 的 自定义 TraitCollection 方法
/// 由于内部是通过 size 判断，不适用于一般的 view 和 vc
extension UIWindow {
    /// 经过定制的 UITraitCollection
    public var lkTraitCollection: UITraitCollection {
        return self.customTraitCollection
    }
}

extension UITraitEnvironment {
    /// 经过定制的 UITraitCollection
    var customTraitCollection: UITraitCollection {
        if !RootTraitCollection.shared.useCustomSizeClass {
            return self.traitCollection
        }
        if let view = self as? UIView {
            return CustomSizeClass.customHorizontalSizeClass(view: view)
        } else if let vc = self as? UIViewController {
            return CustomSizeClass.customHorizontalSizeClass(view: vc.view)
        }
        return self.traitCollection
    }
}

extension UIView {
    func viewController() -> UIViewController? {
        guard let next = next else { return nil }
        if let vc = next as? UIViewController {
            return vc
        }
        return (next as? UIView)?.viewController()
    }
}

extension UIWindow {
    var isRootWindow: Bool {
        if #available(iOS 13.0, *) {
            if let scene = self.windowScene,
                let delegate = scene.delegate as? UIWindowSceneDelegate,
                self == delegate.window.flatMap({ $0 }) {
                return true
            }
        }

        if let rootWindow = UIApplication.shared.delegate?.window.flatMap({ $0 }) {
            return rootWindow == self
        }

        return false
    }
}
