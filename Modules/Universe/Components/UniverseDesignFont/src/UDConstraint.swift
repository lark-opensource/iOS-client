//
//  UDConstraint.swift
//  UniverseDesignFont
//
//  Created by Hayden on 2021/4/29.
//

import UIKit
import Foundation

/// UDConstraint
public enum UDConstraint {

    /// Nothing but returning self.
    public static func fixed(_ num: CGFloat) -> CGFloat {
        return num
    }

    /// Calculate an scaled size by multipling the factor of current zoom level.
    /// - Parameters:
    ///   - num: Number to be converted.
    ///   - zoom: The zoom level for convertion.
    ///   - transformer: The transformer that handle zoom level mapping.
    ///   - roundingRule: The rule for rounding converted number.
    /// - Returns: Number been converted.
    public static func auto(_ num: CGFloat,
                            forZoom zoom: UDZoom = UDZoom.currentZoom,
                            transformer: UDZoom.Transformer = .s6,
                            roundingRule: FloatingPointRoundingRule = .up) -> CGFloat {
        let mappedZoom = transformer.mapper(zoom)
        return (num * mappedZoom.scale).rounded(roundingRule)
    }
}
