//
//  UIViewExtensions.swift
//  ByteViewTab
//
//  Created by kiri on 2021/8/18.
//

import UIKit
import ByteViewCommon

extension UILabel {
    func justReplaceText(to string: String) {
        if let length = attributedText?.length, length > 0 {
            let attributes = attributedText?.attributes(at: 0, effectiveRange: nil)
            attributedText = NSAttributedString(string: string, attributes: attributes)
        } else {
            text = string
        }
    }
}

extension UIButton {
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        vc.setBackgroundColor(color, for: state)
    }
}

extension UIView {
    //返回该view所在VC
    func currentViewController() -> UIViewController? {
        for view in sequence(first: self.superview, next: { $0?.superview }) {
            if let responder = view?.next {
                if responder.isKind(of: UIViewController.self) {
                    return responder as? UIViewController
                }
            }
        }
        return nil
    }

    func toImage() -> UIImage? {
        let transform = self.transform
        self.transform = .identity
        var screenshot: UIImage?

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = self.traitCollection.displayScale > 0 ? self.traitCollection.displayScale : 1.0
        let render = UIGraphicsImageRenderer(bounds: self.bounds, format: format)
        screenshot = render.image { context in
            self.layer.render(in: context.cgContext)
        }

        self.transform = transform
        return screenshot
    }
}
