//
//  FKGradientView.swift
//  FigmaKit
//
//  Created by Hayden on 2019/7/19.
//

import Foundation
import UIKit

public class FKGradientView: UIView, Gradientable {

    public var type: GradientType = .linear {
        didSet {
            gradientLayer.type = type.toSystemType()
        }
    }

    public var colors: [UIColor] = [#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)] {
        didSet {
            if colors.count == 1 { colors += colors }
            let cgColors = colors.map({ $0.cgColor })
            gradientLayer.colors = cgColors
        }
    }

    public var direction: GradientDirection = .leftToRight {
        didSet {
            gradientLayer.direction = direction
        }
    }

    public var locations: [NSNumber]? {
        didSet {
            gradientLayer.locations = locations
        }
    }

    lazy var gradientLayer = FKGradientLayer(type: type)

    public override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        gradientLayer.removeFromSuperlayer()
        gradientLayer.frame = bounds
        gradientLayer.locations = locations
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.direction = direction
        layer.insertSublayer(gradientLayer, at: 0)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *), traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            let colors = colors
            self.colors = colors
        }
    }

    public func updatePattern(_ pattern: GradientPattern, 
                              animated: Bool = true,
                              duration: TimeInterval = 2) {
        CATransaction.begin()
        if animated {
            CATransaction.setAnimationDuration(CFTimeInterval(floatLiteral: duration))
        } else {
            CATransaction.setDisableActions(true)
        }
        defer { CATransaction.commit() }
        type = pattern.type
        colors = pattern.colors
        direction = pattern.direction
        locations = pattern.locations
    }

    public static func fromPattern(_ pattern: GradientPattern) -> FKGradientView {
        let view = FKGradientView()
        view.type = pattern.type
        view.colors = pattern.colors
        view.direction = pattern.direction
        view.locations = pattern.locations
        return view
    }
}

public final class LinearGradientView: FKGradientView {

}

public final class AngularGradientView: FKGradientView {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        type = .angular
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class RadialGradientView: FKGradientView {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        type = .radial
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
