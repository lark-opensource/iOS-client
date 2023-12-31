//
//  UDConstraint+Extension.swift
//  UniverseDesignFont
//
//  Created by Hayden on 2021/4/29.
//

import Foundation
import UIKit

// MARK: - Protocol definition

/// A protocol convert numbers.
public protocol UDConstraintCompatible {
    /// Nothing but returning self.
    func fixed() -> CGFloat
    /// Nothing but returning self.
    static func fixed(_ num: Self) -> CGFloat
    /// Calculate an scaled size by multipling the factor of current zoom level.
    func auto(_ transformer: UDZoom.Transformer, roundingRule: FloatingPointRoundingRule) -> CGFloat
    /// Calculate an scaled size by multipling the factor of current zoom level.
    static func auto(_ num: Self, for transformer: UDZoom.Transformer, roundingRule: FloatingPointRoundingRule) -> CGFloat
}

// MARK: - Extenstion for calling types

/// Make fixed() and auto() compatible for most frequently used type in UI layout.
/// This extension is for the majority of layout situations that require CGFloat value.
extension UDConstraintCompatible where Self: CustomStringConvertible {

    /// Default implimentation for fixed(), returning a CGFloat value.
    public func fixed() -> CGFloat {
        let doubleNum = Double(String(describing: self)) ?? 0
        return UDConstraint.fixed(CGFloat(doubleNum))
    }

    /// Default implimentation for fixed(_:), returning a CGFloat value.
    public static func fixed(_ num: Self) -> CGFloat {
        return num.fixed()
    }

    /// Default implimentation for auto(), returning a CGFloat value.
    public func auto(_ transformer: UDZoom.Transformer = .s6, roundingRule: FloatingPointRoundingRule = .up) -> CGFloat {
        let doubleNum = Double(String(describing: self)) ?? 0
        return UDConstraint.auto(CGFloat(doubleNum), transformer: transformer, roundingRule: roundingRule)
    }

    /// Default implimentation for auto(_:)
    public static func auto(_ num: Self, for transformer: UDZoom.Transformer = .s6, roundingRule: FloatingPointRoundingRule = .up) -> CGFloat {
        return num.auto(transformer, roundingRule: roundingRule)
    }
}

extension Float: UDConstraintCompatible {}
extension Double: UDConstraintCompatible {}
extension Int: UDConstraintCompatible {}
extension UInt: UDConstraintCompatible {}
extension CGFloat: UDConstraintCompatible {}

// MARK: - Extenstion for returning types

/// Make fixed() and auto() return most frequently used type in UI layout.
/// This extenstion is for somewhere requires float point or integer value.
extension UDConstraintCompatible {

    /// Default implimentation for fixed(), returning a BinaryFloatingPoint value.
    public func fixed<F: BinaryFloatingPoint>() -> F {
        return F(fixed())
    }

    /// Default implimentation for fixed(_:), returning a BinaryFloatingPoint value.
    public static func fixed<F: BinaryFloatingPoint>(_ num: Self) -> F {
        return F(num.fixed())
    }

    /// Default implimentation for auto(), returning a BinaryFloatingPoint value.
    public func auto<F: BinaryFloatingPoint>(_ transformer: UDZoom.Transformer = .s6, roundingRule: FloatingPointRoundingRule = .up) -> F {
        return F(auto(transformer, roundingRule: roundingRule))
    }

    /// Default implimentation for auto(_:), returning a BinaryFloatingPoint value.
    public static func auto<F: BinaryFloatingPoint>(_ num: Self, for transformer: UDZoom.Transformer = .s6, roundingRule: FloatingPointRoundingRule = .up) -> F {
        return F(auto(num, for: transformer, roundingRule: roundingRule))
    }
}

extension UDConstraintCompatible {

    /// Default implimentation for fixed(), returning a BinaryInteger value.
    public func fixed<I: BinaryInteger>() -> I {
        return I(fixed())
    }

    /// Default implimentation for fixed(_:), returning a BinaryInteger value.
    public static func fixed<I: BinaryInteger>(_ num: Self) -> I {
        return I(num.fixed())
    }

    /// Default implimentation for auto(), returning a BinaryInteger value.
    public func auto<I: BinaryInteger>(_ transformer: UDZoom.Transformer = .s6, roundingRule: FloatingPointRoundingRule = .up) -> I {
        return I(auto(transformer, roundingRule: roundingRule))
    }

    /// Default implimentation for auto(_:), returning a BinaryInteger value.
    public static func auto<I: BinaryInteger>(_ num: Self, for transformer: UDZoom.Transformer = .s6, roundingRule: FloatingPointRoundingRule = .up) -> I {
        return I(auto(num, for: transformer, roundingRule: roundingRule))
    }
}

// MARK: - Convenient helper

extension CGSize {

    /// Apply auto() to both width and height.
    public func auto(_ transformer: UDZoom.Transformer = .s6, roundingRule: FloatingPointRoundingRule = .up) -> CGSize {
        return CGSize(
            width: width.auto(transformer, roundingRule: roundingRule),
            height: height.auto(transformer, roundingRule: roundingRule)
        )
    }

    /// Make a square with single parameter.
    public static func square(_ side: CGFloat) -> Self {
        return CGSize(width: side, height: side)
    }
}

extension UIEdgeInsets {

    /// Apply auto() to each edge.
    public func auto(_ transformer: UDZoom.Transformer = .s6, roundingRule: FloatingPointRoundingRule = .up) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: top.auto(transformer, roundingRule: roundingRule),
            left: left.auto(transformer, roundingRule: roundingRule),
            bottom: bottom.auto(transformer, roundingRule: roundingRule),
            right: right.auto(transformer, roundingRule: roundingRule)
        )
    }

    /// UIedgeInsets with equivalent edge insets.
    public init(edges: CGFloat) {
        self.init(top: edges, left: edges, bottom: edges, right: edges)
    }

    /// UIedgeInsets with equivalent horizontal and vertical insets.
    public init(horizontal: CGFloat, vertical: CGFloat) {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
}
