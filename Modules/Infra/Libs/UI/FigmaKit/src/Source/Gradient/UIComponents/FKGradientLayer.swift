//
//  FKGradientLayer.swift
//  FigmaKit
//
//  Created by Hayden on 2020/3/24.
//

import Foundation
import UIKit

open class FKGradientLayer: CAGradientLayer {

    open override var type: CAGradientLayerType {
        didSet {
            updateTypeAndDirection()
        }
    }

    public var direction: GradientDirection = .leftToRight {
        didSet {
            updateTypeAndDirection()
        }
    }

    public override init() {
        super.init()
        self.needsDisplayOnBoundsChange = true
    }

    open override var bounds: CGRect {
        didSet {
            if bounds != oldValue, direction.needsFixAngle {
                updateTypeAndDirection()
            }
        }
    }

    public init(type: GradientType) {
        super.init()
        self.type = type.toSystemType()
    }

    /// Make a default linear gradient layer.
    public init(type: GradientType,
                direction: GradientDirection,
                colors: [UIColor],
                locations: [NSNumber]? = nil,
                filter: CIFilter? = nil) {
        super.init()
        self.type = type.toSystemType()
        self.direction = direction
        self.colors = colors.map { $0.cgColor }
        self.locations = locations
        updateTypeAndDirection()
    }

    /// Make a default linear gradient layer.
    public init(direction: GradientDirection,
                colors: [CGColor],
                cornerRadius: CGFloat = 0,
                locations: [NSNumber]? = nil,
                filter: CIFilter? = nil) {
        super.init()
        self.direction = direction
        self.colors = colors
        self.locations = locations
        (self.startPoint, self.endPoint) = direction.startAndEndPointForLinear
        self.cornerRadius = cornerRadius
        if let filter = filter {
            self.backgroundFilters = [filter]
        }
    }

    public override init(layer: Any) {
        super.init(layer: layer)
    }

    required public init(coder aDecoder: NSCoder) {
        super.init()
    }

    public final func clone() -> FKGradientLayer {
        let cgColors: [CGColor]? = colors as? [CGColor]

        if #available(iOS 12.0, *), self.type == .conic {
            let layer = FKGradientLayer(type: .angular)
            layer.direction = direction
            layer.colors = cgColors ?? []
            layer.locations = locations
            return layer
        } else if self.type == .radial {
            let layer = FKGradientLayer(type: .radial)
            layer.direction = direction
            layer.colors = cgColors ?? []
            layer.locations = locations
            return layer
        } else {
            return FKGradientLayer(direction: direction, colors: cgColors ?? [], locations: locations)
        }
    }

    private func updateTypeAndDirection() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        if #available(iOS 12.0, *), type == .conic {
            (startPoint, endPoint) = direction.startAndEndPointForAngular
        } else if type == .radial {
            (startPoint, endPoint) = direction.startAndEndPointForRadial
        } else {
            let (start, end) = direction.startAndEndPointForLinear
            if direction.needsFixAngle {
                (startPoint, endPoint) = LinearGradientFixer.fixPoints(start: start, end: end, bounds: bounds.size)
            } else {
                (startPoint, endPoint) = (start, end)
            }
        }
    }

    public init(with pattern: GradientPattern) {
        super.init()
        updatePattern(pattern, animated: false)
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
        type = pattern.type.toSystemType()
        colors = pattern.colors.map { $0.cgColor }
        direction = pattern.direction
        locations = pattern.locations
    }

    public static func fromPattern(_ pattern: GradientPattern) -> FKGradientLayer {
        let layer = FKGradientLayer()
        layer.type = pattern.type.toSystemType()
        layer.colors = pattern.colors.map { $0.cgColor }
        layer.direction = pattern.direction
        layer.locations = pattern.locations
        return layer
    }
}
