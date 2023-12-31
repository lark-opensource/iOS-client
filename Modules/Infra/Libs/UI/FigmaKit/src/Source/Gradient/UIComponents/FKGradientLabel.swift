//
//  LinearGradientLabel.swift
//  FigmaKit
//
//  Created by Hayden on 2020/4/17.
//

import UIKit

public final class FKGradientLabel: UILabel {

    public var pattern: GradientPattern = .clear {
        didSet {
            setNeedsDisplay()
        }
    }

    public init(pattern: GradientPattern) {
        self.pattern = pattern
        super.init(frame: .zero)
    }

    public static func fromPattern(_ pattern: GradientPattern) -> FKGradientLabel {
        return .init(pattern: pattern)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func drawText(in rect: CGRect) {
        self.textColor = UIColor.fromGradientWithDirection(
            pattern.direction,
            frame: rect,
            colors: pattern.colors,
            locations: pattern.locations)
        super.drawText(in: rect)
    }
}

public final class LinearGradientLabel: UILabel {

    public var direction: GradientDirection = .leftToRight {
        didSet { setNeedsDisplay() }
    }

    public var colors: [UIColor] = [.black, .black] {
        didSet {
            if colors.count == 1 { colors += colors }
            setNeedsDisplay()
        }
    }

    public var locations: [NSNumber]? {
        didSet { setNeedsDisplay() }
    }

    public override func drawText(in rect: CGRect) {
        self.textColor = UIColor.fromGradientWithDirection(
            direction,
            frame: rect,
            colors: colors,
            locations: locations)
        super.drawText(in: rect)
    }
}
