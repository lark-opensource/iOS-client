//
//  UIBezierPath+SwiftUI.swift
//  ExampleApp (iOS)
//
//  Created by Hayden Wang on 2022/4/6.
//

import Foundation
import UIKit
import SwiftUI

// swiftlint:disable all

// ignore magic number checking for UI
// disable-lint: magic number

// MARK: - UIBezierPath

@available(iOS 14.0, *)
extension UIBezierPath {

    static var squircle: UIBezierPath {
        return pathForMaxSmoothLevel(forRect: CGRect(x: 0, y: 0, width: 1, height: 1), cornerRadius: 0.25)
    }

    static func pathForMaxSmoothLevel(forRect bounds: CGRect,
                                      cornerRadius: CGFloat,
                                      roundedCorners: UIRectCorner = .allCorners) -> UIBezierPath {
        let r = cornerRadius
        let a = r * 0.292893218813
        let b = a * 2
        let c = r * 1.057191
        let d = r * 2

        let w = bounds.width
        let h = bounds.height
        let bezierPath = UIBezierPath()

        // start point at top left
        bezierPath.move(to: CGPoint(x: 0, y: d))
        // top left corner
        if roundedCorners.contains(.topLeft) {
            bezierPath.addCurve(to: CGPoint(x: a, y: a), controlPoint1: CGPoint(x: 0, y: c), controlPoint2: CGPoint(x: 0, y: b))
            bezierPath.addCurve(to: CGPoint(x: d, y: 0), controlPoint1: CGPoint(x: b, y: 0), controlPoint2: CGPoint(x: c, y: 0))
        } else {
            bezierPath.addLine(to: CGPoint(x: 0, y: 0))
        }
        // top line
        bezierPath.addLine(to: CGPoint(x: w - d, y: 0))
        // top right corner
        if roundedCorners.contains(.topRight) {
            bezierPath.addCurve(to: CGPoint(x: w - a, y: a), controlPoint1: CGPoint(x: w - c, y: 0), controlPoint2: CGPoint(x: w - b, y: 0))
            bezierPath.addCurve(to: CGPoint(x: w, y: d), controlPoint1: CGPoint(x: w, y: b), controlPoint2: CGPoint(x: w, y: c))
        } else {
            bezierPath.addLine(to: CGPoint(x: w, y: 0))
        }
        // right line
        bezierPath.addLine(to: CGPoint(x: w, y: h - d))
        // bottom right corner
        if roundedCorners.contains(.bottomRight) {
            bezierPath.addCurve(to: CGPoint(x: w - a, y: h - a), controlPoint1: CGPoint(x: w, y: h - c), controlPoint2: CGPoint(x: w, y: h - b))
            bezierPath.addCurve(to: CGPoint(x: w - d, y: h), controlPoint1: CGPoint(x: w - b, y: h), controlPoint2: CGPoint(x: w - c, y: h))
        } else {
            bezierPath.addLine(to: CGPoint(x: w, y: h))
        }
        // bottom line
        bezierPath.addLine(to: CGPoint(x: d, y: h))
        // bottom left corner
        if roundedCorners.contains(.bottomLeft) {
            bezierPath.addCurve(to: CGPoint(x: a, y: h - a), controlPoint1: CGPoint(x: c, y: h), controlPoint2: CGPoint(x: b, y: h))
            bezierPath.addCurve(to: CGPoint(x: 0, y: h - d), controlPoint1: CGPoint(x: 0, y: h - b), controlPoint2: CGPoint(x: 0, y: h - c))
        } else {
            bezierPath.addLine(to: CGPoint(x: 0, y: h))
        }
        // left line
        bezierPath.addLine(to: CGPoint(x: 0, y: d))
        // back to start point
        bezierPath.close()
        return bezierPath
    }
}

/// G2 连续的圆角矩形
@available(iOS 14.0, *)
struct ScaledBezier: Shape {
    let bezierPath: UIBezierPath

    func path(in rect: CGRect) -> Path {
        let path = Path(bezierPath.cgPath)

        // Figure out how much bigger we need to make our path in order for it to fill the available space without clipping.
        let multiplier = min(rect.width, rect.height)

        // Create an affine transform that uses the multiplier for both dimensions equally.
        let transform = CGAffineTransform(scaleX: multiplier, y: multiplier)

        // Apply that scale and send back the result.
        return path.applying(transform)
    }
}

// MARK: - Shape

@available(iOS 14.0, *)
struct Squircle: Shape {

    func path(in rect: CGRect) -> Path {
        let squircle = UIBezierPath.pathForMaxSmoothLevel(
            forRect: CGRect(x: 0, y: 0, width: 1, height: 1),
            cornerRadius: 0.25
        )
        // Figure out how much bigger we need to make our path in order for it to fill the available space without clipping.
        let multiplier = min(rect.width, rect.height)
        // Create an affine transform that uses the multiplier for both dimensions equally.
        let transform = CGAffineTransform(scaleX: multiplier, y: multiplier)
        // Apply that scale and send back the result.
        return Path(squircle.cgPath).applying(transform)
    }
}

@available(iOS 14.0, *)
extension Shape {
    func fill<Fill: ShapeStyle, Stroke: ShapeStyle>(_ fillStyle: Fill, strokeBorder strokeStyle: Stroke, lineWidth: CGFloat = 1) -> some View {
        self
            .stroke(strokeStyle, lineWidth: lineWidth)
            .widgetBackground(self.fill(fillStyle))
    }
}

@available(iOS 14.0, *)
extension InsettableShape {
    func fill<Fill: ShapeStyle, Stroke: ShapeStyle>(_ fillStyle: Fill, strokeBorder strokeStyle: Stroke, lineWidth: CGFloat = 1) -> some View {
        self
            .strokeBorder(strokeStyle, lineWidth: lineWidth)
            .widgetBackground(self.fill(fillStyle))
    }
}

// MARK: - Text

@available(iOS 14.0, *)
extension Text {
    func udFont(_ size: CGFloat, weight: Font.Weight = .regular, lineHeight: CGFloat = 1) -> some View {
        let uiFont = UIFont.systemFont(ofSize: size)
        return self
            .font(.system(size: size, weight: weight))
            .lineSpacing(lineHeight - uiFont.lineHeight)
            .padding(.vertical, (lineHeight - uiFont.lineHeight) / 2)
    }
}

// MARK: - Color

@available(iOS 14.0, *)
extension Color {
    init(_ hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

@available(iOS 14.0, *)
extension Color {
    init?(_ hex: String) {
        var str = hex
        if str.hasPrefix("#") {
            str.removeFirst()
        }
        if str.count == 3 {
            str = String(repeating: str[str.startIndex], count: 2)
            + String(repeating: str[str.index(str.startIndex, offsetBy: 1)], count: 2)
            + String(repeating: str[str.index(str.startIndex, offsetBy: 2)], count: 2)
        } else if !str.count.isMultiple(of: 2) || str.count > 8 {
            return nil
        }
        let scanner = Scanner(string: str)
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        if str.count == 2 {
            let gray = Double(Int(color) & 0xFF) / 255
            self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: 1)
        } else if str.count == 4 {
            let gray = Double(Int(color >> 8) & 0x00FF) / 255
            let alpha = Double(Int(color) & 0x00FF) / 255
            self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: alpha)
        } else if str.count == 6 {
            let red = Double(Int(color >> 16) & 0x0000FF) / 255
            let green = Double(Int(color >> 8) & 0x0000FF) / 255
            let blue = Double(Int(color) & 0x0000FF) / 255
            self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
        } else if str.count == 8 {
            let red = Double(Int(color >> 24) & 0x000000FF) / 255
            let green = Double(Int(color >> 16) & 0x000000FF) / 255
            let blue = Double(Int(color >> 8) & 0x000000FF) / 255
            let alpha = Double(Int(color) & 0x000000FF) / 255
            self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
        } else {
            return nil
        }
    }
}

extension String {

    /// Return the row width of current string in specified font within constrainted height.
    func getWidth(withConstrainedHeight height: CGFloat = .greatestFiniteMagnitude, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font],
            context: nil
        )
        return ceil(boundingBox.width)
    }
}

// swiftlint:enable all
