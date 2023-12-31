//
//  UIImageView+Theme.swift
//  UniverseDesignTheme
//
//  Created by 姚启灏 on 2021/6/4.
//

import Foundation
import UIKit

public extension UDComponentsExtension where BaseType: UIImageView {

    /// Set mask view to UIImageView.
    /// Show only in dark mode
    func setMaskView() {
        base.imageMaskView = UIView()
    }

    /// Remove mask view to UIImageView
    func removeMaskView() {
        base.imageMaskView = nil
    }
}

extension UIImageView {

    private struct AssociatedKeys {
        static var MaskView = "ud_image_maskview"
    }

    var imageMaskView: UIView? {
        get {
            guard #available(iOS 13.0, *) else { return nil }
            return objc_getAssociatedObject(
                self, &AssociatedKeys.MaskView
            ) as? UIView
        }
        set {
            guard #available(iOS 13.0, *) else { return }
            guard newValue != imageMaskView else { return }
            let oldImageMaskView = imageMaskView
            oldImageMaskView?.removeFromSuperview()
            if let newImageMaskView = newValue {
                newImageMaskView.isUserInteractionEnabled = false
                newImageMaskView.backgroundColor = UIColor(dynamicProvider: { trait in
                    switch trait.userInterfaceStyle {
                    case .dark:
                        return UIColor.black.withAlphaComponent(0.12)
                    default:
                        return UIColor.clear
                    }
                })
                addSubview(newImageMaskView)

                newImageMaskView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    newImageMaskView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                    newImageMaskView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                    newImageMaskView.topAnchor.constraint(equalTo: self.topAnchor),
                    newImageMaskView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
                ])

                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.MaskView,
                    newImageMaskView,
                    .OBJC_ASSOCIATION_RETAIN
                )
            }
        }
    }
}
