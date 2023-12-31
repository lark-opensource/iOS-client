//
//  UIView+SafeArea.swift
//  MessageListDemo
//
//  Created by 谭志远 on 2019/6/11.
//

import Foundation
import UIKit

extension UIView {
    class func executeOnMainThread(_ block: @escaping () -> Void) {
        if Thread.current.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }

    func addCorner(_ corners: UIRectCorner,
                          _ radius: CGFloat,
                          withRadii radii: CGSize) {

        //frame可以先计算完成  避免圆角拉伸

        let path: UIBezierPath = UIBezierPath(roundedRect: CGRect(x: 0,
                                                                  y: 0,
                                                                  width: radii.width,
                                                                  height: radii.height),
                                              byRoundingCorners: corners,
                                              cornerRadii: CGSize(width: radius,
                                                                  height: radius))
        let maskLayer: CAShapeLayer = CAShapeLayer()
        maskLayer.frame = CGRect(x: 0, y: 0, width: radii.width, height: radii.height)
        maskLayer.path = path.cgPath
        self.layer.mask = maskLayer
    }

    var firstResponder: UIView? {
        guard !isFirstResponder else { return self }
        for subview in subviews {
            if let firstResponder = subview.firstResponder {
                return firstResponder
            }
        }
        return nil
    }

    var screenFrame: CGRect {
        if let window = window {
            let windowFrame = convert(bounds, to: nil)
            return window.convert(windowFrame, to: nil)
        } else {
            return .zero
        }
    }
}
