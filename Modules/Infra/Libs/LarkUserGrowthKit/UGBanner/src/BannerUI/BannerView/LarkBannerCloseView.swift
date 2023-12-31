//
//  LarkBannerCloseView.swift
//  LarkBanner
//
//  Created by mochangxing on 2020/5/30.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignColor

final class LarkBannerCloseView: UIControl {

    var color: UIColor = UIColor.ud.iconN2 {
        didSet {
            self.setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        let bezierPath = UIBezierPath()

        bezierPath.move(to: CGPoint(x: LarkBannerCloseView.Layout.margin,
                                y: LarkBannerCloseView.Layout.margin))
        bezierPath.addLine(to: CGPoint(x: rect.width - LarkBannerCloseView.Layout.margin,
                                   y: rect.height - LarkBannerCloseView.Layout.margin))
        bezierPath.move(to: CGPoint(x: rect.width - LarkBannerCloseView.Layout.margin,
                                y: LarkBannerCloseView.Layout.margin ))
        bezierPath.addLine(to: CGPoint(x: LarkBannerCloseView.Layout.margin,
                                   y: rect.height - LarkBannerCloseView.Layout.margin ))

        color.setFill()
        color.setStroke()
        bezierPath.lineWidth = LarkBannerCloseView.Layout.lineWidth
        bezierPath.lineCapStyle = .square
        bezierPath.fill()
        bezierPath.stroke()
    }
}

extension LarkBannerCloseView {
    enum Layout {
        static let lineWidth: CGFloat = 1.3
        static let margin: CGFloat = 9
    }
}
