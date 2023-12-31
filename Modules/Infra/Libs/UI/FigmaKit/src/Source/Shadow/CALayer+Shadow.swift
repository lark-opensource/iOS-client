//
//  CALayer+Shadow.swift
//  FigmaKit
//
//  Created by Hayden Wang on 2021/8/2.
//

import Foundation
import UIKit

// swiftlint:disable all

public extension CALayer {

    func dropShadow(color: UIColor = .black,
                     alpha: Float = 0.5,
                     x: CGFloat = 0,
                     y: CGFloat = 2,
                     blur: CGFloat = 4,
                     spread: CGFloat = 0,
                     path: UIBezierPath? = nil) {
        shadowColor = color.cgColor
        shadowOpacity = alpha
        shadowRadius = blur / 2
        if let path = path {
            if spread == 0 {
                shadowOffset = CGSize(width: x, height: y)
            } else {
                let scaleX = (path.bounds.width + (spread * 2)) / path.bounds.width
                let scaleY = (path.bounds.height + (spread * 2)) / path.bounds.height

                path.apply(CGAffineTransform(translationX: x + -spread, y: y + -spread).scaledBy(x: scaleX, y: scaleY))
                shadowPath = path.cgPath
            }
        } else {
            shadowOffset = CGSize(width: x, height: y)
            if spread == 0 {
                shadowPath = nil
            } else {
                let dx = -spread
                let rect = bounds.insetBy(dx: dx, dy: dx)
                shadowPath = UIBezierPath(rect: rect).cgPath
            }
        }
        shouldRasterize = true
        rasterizationScale = UIScreen.main.scale
    }

    private func dropShadowBackup(
        color: UIColor = .black,
        alpha: Float = 0.5,
        x: CGFloat = 0,
        y: CGFloat = 2,
        blur: CGFloat = 4,
        spread: CGFloat = 0)
    {
        masksToBounds = false
        shadowColor = color.cgColor
        shadowOpacity = alpha
        shadowOffset = CGSize(width: x, height: y)
        shadowRadius = blur / 2
        if spread == 0 {
            shadowPath = nil
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            shadowPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius + spread).cgPath
        }
    }
}
// swiftlint:enable all
