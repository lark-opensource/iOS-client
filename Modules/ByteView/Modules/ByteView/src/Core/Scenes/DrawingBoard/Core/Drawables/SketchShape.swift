//
//  SketchShape.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/11/21.
//

import Foundation
import CoreGraphics
import UIKit

public typealias ShapeID = String

extension ShapeID {
    static var none: ShapeID = ""
}

// MARK: - Style

public struct ArrowPaintStyle {
    public let color: UIColor
    public let size: CGFloat

    static var `default` = ArrowPaintStyle(color: .red,
                                           size: 3)
}

public struct CometPaintStyle {
    public let color: UIColor
    public let size: CGFloat
    public let opacity: CGFloat

    static var `default` = CometPaintStyle(color: .red,
                                           size: 10,
                                           opacity: 0.5)
}

public struct OvalPaintStyle {
    public let color: UIColor
    public let size: CGFloat

    static var `default` = OvalPaintStyle(color: .red,
                                          size: 5)
}

public typealias PencilPaintType = UInt32
extension PencilPaintType {
    static var `default` = PencilPaintType(1)
    static var marker = PencilPaintType(2)
}

public struct PencilPaintStyle {
    public let color: UIColor
    public let size: CGFloat
    public let pencilType: PencilPaintType

    public init(color: UIColor,
                size: CGFloat? = nil,
                pencilType: PencilPaintType) {
        self.pencilType = pencilType
        var penSize: CGFloat = 0
        switch pencilType {
        case .marker:
            self.color = color.withAlphaComponent(0.4)
            penSize = 18
        default:
            self.color = color
            penSize = 3
        }
        if let remoteSize = size {
            penSize = remoteSize
        }
        self.size = penSize
    }
}

public struct RectanglePaintStyle {
    public let color: UIColor
    public let size: CGFloat

    static var `default` = RectanglePaintStyle(color: .red,
                                               size: 5)
}

// MARK: - Drawable

public protocol SketchShape: CustomStringConvertible, SketchDrawable {
    var id: ShapeID { get }
    var userIdentifier: String { get }
}

extension SketchShape {
    var description: String {
        "Shape(\(id))"
    }
}

struct TextStyle {
    var textColor: UIColor
    var font: UIFont
    var backgroundColor: UIColor
    var cornerRadius: CGFloat

    init(textColor: UIColor,
         font: UIFont,
         backgroundColor: UIColor,
         cornerRadius: CGFloat = 2) {
        self.textColor = textColor
        self.font = font
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }
}

public struct OvalDrawable: SketchShape {
    public let id: ShapeID
    public let frame: CGRect
    public let style: OvalPaintStyle
    public var userIdentifier: String = ""

    public init(id: ShapeID,
                frame: CGRect,
                style: OvalPaintStyle,
                userIdentifier: String = "") {
        self.id = id
        self.frame = frame
        self.style = style
        self.userIdentifier = userIdentifier
    }

    public func drawIn(context: CGContext) {
        context.saveGState()
        defer {
            context.restoreGState()
        }
        context.setLineWidth(style.size)
        context.setStrokeColor(style.color.cgColor)
        context.addPath(self.path)
        context.strokePath()
    }

    public var description: String {
        "Oval(id: \(id), frame: \(frame))"
    }
}

public struct RectangleDrawable: SketchShape {
    public let id: ShapeID
    public let frame: CGRect
    public let style: RectanglePaintStyle
    public var userIdentifier: String = ""

    public init(id: ShapeID,
                frame: CGRect,
                style: RectanglePaintStyle,
                userIdentifier: String = "") {
        self.id = id
        self.frame = frame
        self.style = style
        self.userIdentifier = userIdentifier
    }

    public func drawIn(context: CGContext) {
        context.saveGState()
        defer {
            context.restoreGState()
        }
        context.setLineWidth(style.size)
        context.setStrokeColor(style.color.cgColor)
        context.addPath(self.path)
        context.strokePath()
    }

    public var description: String {
        "Rect(id: \(id), frame: \(frame))"
    }
}

public struct ArrowDrawable: SketchShape {
    public let id: ShapeID
    public let start: CGPoint
    public let end: CGPoint
    public let style: ArrowPaintStyle
    public var userIdentifier: String = ""

    public var description: String {
        "Arrow(id: \(id), start: \(start), end: \(end))"
    }

    public init(id: ShapeID,
                start: CGPoint,
                end: CGPoint,
                style: ArrowPaintStyle,
                userIdentifier: String = "") {
        self.id = id
        self.start = start
        self.end = end
        self.style = style
        self.userIdentifier = userIdentifier
    }

    public func drawIn(context: CGContext) {
        context.saveGState()
        defer {
            context.restoreGState()
        }
        context.setFillColor(style.color.cgColor)
        context.addPath(self.path)
        context.fillPath()
    }
}

public struct PencilPathDrawable: SketchShape {

    public enum Dimension: Int32, Codable {
        case linear = 1
        case quadratic = 2
        case cubic = 3
    }

    public let id: ShapeID
    public var points: [CGPoint]
    public let dimension: Dimension
    public let pause: Bool
    public let finish: Bool
    public let style: PencilPaintStyle
    public var userIdentifier: String = ""

    public var description: String {
        "Pencil(id: \(id), pointsCount: \(points.count))"
    }

    public init(id: ShapeID,
                points: [CGPoint],
                dimension: Dimension = .linear,
                pause: Bool,
                finish: Bool,
                style: PencilPaintStyle,
                userIdentifier: String = "") {
        self.id = id
        self.points = points
        self.dimension = dimension
        self.pause = pause
        self.finish = finish
        self.style = style
        self.userIdentifier = userIdentifier
    }

    public func drawIn(context: CGContext) {
        context.saveGState()
        defer {
            context.restoreGState()
        }
        context.setLineWidth(style.size)
        context.setStrokeColor(style.color.cgColor)
        context.addPath(self.path)
        context.strokePath()
    }
}

public struct NicknameDrawable: SketchShape {
    public var id: ShapeID
    let text: String
    let style: TextStyle
    let leftCenter: CGPoint
    public var userIdentifier: String

    init(id: ShapeID,
         text: String,
         style: TextStyle,
         leftCenter: CGPoint,
         userIdentifier: String = "") {
        self.id = id
        self.text = text
        self.style = style
        self.leftCenter = leftCenter
        self.userIdentifier = userIdentifier
    }

    public var description: String {
        "NickName(id: \(id))"
    }

    public func drawIn(context: CGContext) {
        return
    }
}

struct CometSnippetDrawable: SketchShape {
    let id: ShapeID
    let points: [CGPoint]
    let radius: [CGFloat]
    let pause: Bool
    let exit: Bool
    let minDistance: CGFloat
    let cometStyle: CometPaintStyle
    var userIdentifier: String

    func drawIn(context: CGContext) {
        let factor: CGFloat = 1 / (minDistance * minDistance)
        zip(points, radius).forEach { [factor] center, radius in
            context.setFillColor(cometStyle.color.withAlphaComponent(radius * radius * factor).cgColor)
            let rect = CGRect(x: center.x - radius,
                              y: center.y - radius,
                              width: radius * 2,
                              height: radius * 2)
            context.fillEllipse(in: rect)
        }
    }

    var description: String {
        "CometSnippet(id: \(id), pointsCount: \(points.count), radiusCount: \(radius.count), paused: \(pause))"
    }

}
