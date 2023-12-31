//
//  UIView+ExternalBorder.swift
//  UniverseDesignAvatar
//
//  Created by 郭怡然 on 2022/8/25.
//

import UIKit
import Foundation
extension UIImageView {

    struct Constants {
        static let ExternalBorderName = "externalBorder"
    }

    func addExternalBorder(borderWidth: CGFloat = 2.0, borderColor: UIColor = UIColor.ud.primaryOnPrimaryFill) -> CALayer {
        let externalBorder = CALayer()
        externalBorder.frame = CGRect(x: -borderWidth, y: -borderWidth, width: frame.size.width + 2 * borderWidth, height: frame.size.height + 2 * borderWidth)
        externalBorder.borderWidth = borderWidth
        externalBorder.name = Constants.ExternalBorderName

        ///加到最底层
        layer.insertSublayer(externalBorder, at: 0)
        layer.masksToBounds = false
        externalBorder.ud.setBorderColor(borderColor)
        let mask = CALayer()
        mask.frame = CGRect(x: -borderWidth, y: -borderWidth, width: frame.size.width + 2 * borderWidth, height: frame.size.height + 2 * borderWidth)
        mask.borderWidth = borderWidth
        //这个地方设背景颜色是为了撑开mask，否则mask只有border没有内部
        mask.backgroundColor = UIColor.ud.yellow.cgColor
        if frame.width != 0 {
            externalBorder.cornerRadius = layer.cornerRadius * externalBorder.frame.width / frame.width
            mask.cornerRadius = layer.cornerRadius * externalBorder.frame.width / frame.width
        }
        ///加到最外层
        layer.addSublayer(mask)
        layer.mask = mask
        mask.ud.setBorderColor(borderColor)
        return externalBorder
    }

    func removeExternalBorders() {
        layer.sublayers?.filter() { $0.name == Constants.ExternalBorderName }.forEach() {
            $0.removeFromSuperlayer()
        }
    }

    func removeExternalBorder(externalBorder: CALayer) {
        guard externalBorder.name == Constants.ExternalBorderName else { return }
        externalBorder.removeFromSuperlayer()
    }

}
