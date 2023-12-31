//
//  CornerSmoothLevel.swift
//  FigmaKit
//
//  Created by Hayden Wang on 2021/9/4.
//

import UIKit
import Foundation

public enum CornerSmoothLevel: String, CustomStringConvertible {

    /// Corner with no smoothing effect.
    ///
    /// Corresponds to **0%** corner smoothing value in Figma.
    case none

    /// Corner with smoothing effect that iOS uses as default.
    ///
    /// Corresponds to **60%** corner smoothing value in Figma.
    case natural

    /// Corner with maximum smoothing effect.
    ///
    /// Corresponds to **100%** corner smoothing value in Figma.
    case max

    public var value: CGFloat {
        switch self {
        case .none:     return 0
        case .natural:  return 0.6
        case .max:      return 1.0
        }
    }

    /// A textual representation of soomth level.
    public var description: String {
        return self.rawValue
    }
}

public struct CornerRadii: ExpressibleByFloatLiteral, ExpressibleByArrayLiteral {

    var topLeft: CGFloat
    var topRight: CGFloat
    var bottomLeft: CGFloat
    var bottomRight: CGFloat

    public init(tl: CGFloat, tr: CGFloat, br: CGFloat, bl: CGFloat) {
        self.topLeft = tl
        self.topRight = tr
        self.bottomLeft = bl
        self.bottomRight = br
    }

    public init(_ value: CGFloat) {
        self.init(tl: value, tr: value, br: value, bl: value)
    }

    public init(cornerRadius: CGFloat, roundedCorners: UIRectCorner) {
        self.topLeft = roundedCorners.contains(.topLeft) ? cornerRadius : 0
        self.topRight = roundedCorners.contains(.topRight) ? cornerRadius : 0
        self.bottomLeft = roundedCorners.contains(.bottomLeft) ? cornerRadius : 0
        self.bottomRight = roundedCorners.contains(.bottomRight) ? cornerRadius : 0
    }

    // ExpressibleByFloatLiteral

    public typealias FloatLiteralType = Float

    public init(floatLiteral value: FloatLiteralType) {
        let cgValue = CGFloat(value)
        self.init(cgValue)
    }

    // ExpressibleByArrayLiteral

    public typealias ArrayLiteralElement = CGFloat

    public init(arrayLiteral elements: CGFloat...) {
        guard elements.count == 4 else {
            fatalError("Corner radii should init with 4 params.")
        }
        self.init(tl: elements[0], tr: elements[1], br: elements[2], bl: elements[3])
    }
}
