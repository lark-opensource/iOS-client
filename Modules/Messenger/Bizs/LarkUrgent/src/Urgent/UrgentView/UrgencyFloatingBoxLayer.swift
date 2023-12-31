//
//  PushCardFloatingBoxLayer.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/9/26.
//

import Foundation
import UIKit
import LKWindowManager

final class UrgencyBoxLayer: CALayer {

    init(frame: CGRect) {
        super.init()
        // swiftlint:disable all
        self.shadowColor = UIColor(red: 252.0 / 255.0, green: 118.0 / 255.0, blue: 91.0 / 255.0, alpha: 1.0).cgColor
        // swiftlint:enable all
        self.shadowOffset = CGSize(width: 0, height: 3)
        self.shadowOpacity = 0.3
        self.shadowRadius = 6.0
        self.addSublayer(setUrgencyLayer(frame: frame))
    }

    private func setUrgencyLayer(frame: CGRect) -> CALayer {
        let orientation = Utility.getCurrentInterfaceOrientation() ?? .portrait
        let path = UIBezierPath(
            roundedRect: frame,
            byRoundingCorners: (orientation == .landscapeLeft && UIDevice.current.userInterfaceIdiom == .phone) ?
            [.topRight, .bottomRight] : [.topLeft, .bottomLeft],
            cornerRadii: CGSize(width: frame.height / 2, height: frame.height / 2)
        )
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = frame
        shapeLayer.path = path.cgPath

        let gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        let colors = [UIColor.ud.R400.cgColor, UIColor.ud.colorfulRed.cgColor]
        gradientLayer.colors = colors
        gradientLayer.mask = shapeLayer
        return gradientLayer
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
