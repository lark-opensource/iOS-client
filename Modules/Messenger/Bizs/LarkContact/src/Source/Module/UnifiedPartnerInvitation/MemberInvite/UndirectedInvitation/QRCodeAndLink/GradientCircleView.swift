//
//  GradientCircleView.swift
//  LarkContact
//
//  Created by YuankaiZhu on 2023/7/25.
//

import UIKit
import LarkUIKit

class GradientCircleView: UIView {

    class RadialGradientLayer: CAGradientLayer {

        override init() {
            super.init()
            self.type = .radial
            startPoint = CGPoint(x: 0.5, y: 0.5)
            endPoint = CGPoint(x: 1, y: 1)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override init(layer: Any) {
            super.init(layer: layer)
        }

    }

    private lazy var gradientLayer = RadialGradientLayer()

    init() {
        super.init(frame: .zero)
        gradientLayer.locations = [0, 1]
        self.layer.addSublayer(gradientLayer)
    }

    func setColors(color: UIColor, opacity: CGFloat) {
        gradientLayer.colors = [color.withAlphaComponent(opacity).cgColor, UIColor.clear.cgColor]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = self.bounds
    }
}
