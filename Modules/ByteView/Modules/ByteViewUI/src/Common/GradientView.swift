//
//  GradientView.swift
//  ByteView
//
//  Created by 李凌峰 on 8/1/2019.
//

import UIKit

public class GradientView: UIView {

    public override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    // swiftlint:disable force_cast
    public var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
    // swiftlint:enable force_cast

    public var colors: [UIColor]? {
        get {
            return (gradientLayer.colors as? [CGColor]).flatMap { $0.compactMap { UIColor(cgColor: $0) } }
        }

        set {
            if let colors = newValue {
                gradientLayer.ud.setColors(colors, bindTo: self)
            } else {
                gradientLayer.colors = newValue.flatMap { $0.compactMap { $0.cgColor } }
            }
        }
    }

    public var startPoint: CGPoint {
        get {
            return gradientLayer.startPoint
        }

        set {
            gradientLayer.startPoint = newValue
        }
    }

    public var endPoint: CGPoint {
        get {
            return gradientLayer.endPoint
        }

        set {
            gradientLayer.endPoint = newValue
        }
    }

}

public extension GradientView {

    enum Direction {
        case horizontal
        case vertical
    }

    func spreadUniformly(_ colors: [UIColor], to direction: Direction) {
        switch direction {
        case .horizontal:
            startPoint = CGPoint(x: 0.0, y: 0.5)
            endPoint = CGPoint(x: 1.0, y: 0.5)
        case .vertical:
            startPoint = CGPoint(x: 0.5, y: 0.0)
            endPoint = CGPoint(x: 0.5, y: 1.0)
        }
        self.colors = colors
    }

}
