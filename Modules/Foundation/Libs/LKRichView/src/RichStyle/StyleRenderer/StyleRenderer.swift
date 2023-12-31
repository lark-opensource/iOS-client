//
//  StyleRenderer.swift
//  LKRichView
//
//  Created by qihongye on 2019/10/31.
//

import UIKit
import Foundation

struct BorderEdgeRenderModel {
    var a: CGPoint, b: CGPoint, c: CGPoint, d: CGPoint
    let color: UIColor
    let style: BorderEdge.Style

    var dashLineInfo: DashLineInfo?

    init(a: CGPoint, b: CGPoint, c: CGPoint, d: CGPoint, _ color: UIColor, _ style: BorderEdge.Style) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.color = color
        self.style = style
    }

    func draw(paintInfo: PaintInfo) {
        let context = paintInfo.graphicsContext
        context.saveGState()
        if style == .dashed, let info = dashLineInfo {
            let path = UIBezierPath()
            path.move(to: info.startPoint)
            path.addLine(to: info.endPoint)
            path.lineWidth = abs(info.lineWidth)
            context.setLineDash(phase: 0, lengths: [2, 2])
            context.setStrokeColor(color.cgColor)
            context.addPath(path.cgPath)
            context.strokePath()
        } else {
            let path = UIBezierPath()
            path.move(to: a)
            path.addLine(to: b)
            path.addLine(to: c)
            path.addLine(to: d)
            path.close()
            context.addPath(path.cgPath)
            context.setFillColor(color.cgColor)
            context.fillPath()
        }
        context.restoreGState()
    }

    struct DashLineInfo {
        var startPoint: CGPoint
        var endPoint: CGPoint
        var lineWidth: CGFloat
    }
}

struct BorderEdgeRadiusRenderModel {
    var a: CGPoint, b: CGPoint, c: CGPoint, d: CGPoint, c1: CGPoint, c2: CGPoint
    let colors: [UIColor]

    init(a: CGPoint, b: CGPoint, c1: CGPoint, c: CGPoint, d: CGPoint, c2: CGPoint, _ colors: [UIColor]) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.c1 = c1
        self.c2 = c2
        self.colors = colors
    }

    func draw(paintInfo: PaintInfo) {
        let context = paintInfo.graphicsContext
        let path = UIBezierPath()
        path.move(to: a)
        path.addQuadCurve(to: b, controlPoint: c1)
        path.addLine(to: c)
        path.addQuadCurve(to: d, controlPoint: c2)
        path.close()
        context.saveGState()

        // 至多两种颜色，不论是有 1 种颜色还是 2 种，都先按第 1 种填充满整个区域
        if let color = colors.first {
            context.addPath(path.cgPath)
            context.setFillColor(color.cgColor)
            context.fillPath()
        }
        // 如果有第二种，在原先 path 的基础上，绘制第 2 种颜色；2 种以外的颜色会被忽略
        if colors.count >= 2 {
            let coverPath = UIBezierPath()
            coverPath.move(to: b)
            coverPath.addLine(to: c1)
            coverPath.addLine(to: .init(x: c.x, y: d.y))
            coverPath.close()
            // 需要裁剪掉 coverPath 在 path 外的部分
            path.addClip()
            context.addPath(coverPath.cgPath)
            context.setFillColor(colors[1].cgColor)
            context.fillPath()
        }

        context.restoreGState()
    }
}

struct StyleRenderer {
    static func render(style: RenderStyleOM, paintInfo: PaintInfo, renderObject: RenderObject) {
        let context = paintInfo.graphicsContext
        /// draw background
        if let bgColor = style.backgroundColor {
            let path = getBorderPath(style: style, rect: renderObject.paddingRect)
            context.addPath(path)
            context.setFillColor(bgColor.cgColor)
            context.fillPath()
        }
        /// draw border
        if let border = style.border {
            drawBorders(
                paintInfo: paintInfo, border: border, borderRadius: style.borderRadius,
                fontSize: style.font.pointSize, rect: renderObject.paddingRect
            )
        }
    }

    /// CoreText coordinate, origin is bottom-left corner.
    /// A B C D E F G H 8 points to calculate border path.
    /// step 1.
    ///     Connecting A B C
    /// step 2.
    ///     Connecting C D E
    /// step 3.
    ///     Connecting E F G
    /// step 4.
    ///     Connecting G H A
    /// C1-C--------D-C2
    /// B             E
    /// |             |
    /// A             F
    /// C4-H--------G-C3
    private static func getBorderPath(style: RenderStyleOM, rect: CGRect) -> CGPath {
        guard let borderRadius = style.borderRadius else {
            return CGPath(rect: rect, transform: nil)
        }
        let fontSize = style.font.pointSize
        let topLeft = getActualLengthSize(borderRadius.topLeft, fontSize: fontSize, rect: rect)
        let topRight = getActualLengthSize(borderRadius.topRight, fontSize: fontSize, rect: rect)
        let bottomRight = getActualLengthSize(borderRadius.bottomRight, fontSize: fontSize, rect: rect)
        let bottomLeft = getActualLengthSize(borderRadius.bottomLeft, fontSize: fontSize, rect: rect)

        let A = CGPoint(x: rect.minX, y: rect.minY + bottomLeft.height)
        let B = CGPoint(x: rect.minX, y: rect.maxY - topLeft.height)
        let C = CGPoint(x: rect.minX + topLeft.width, y: rect.maxY)
        let D = CGPoint(x: rect.maxX - topRight.width, y: rect.maxY)
        let E = CGPoint(x: rect.maxX, y: rect.maxY - topRight.height)
        let F = CGPoint(x: rect.maxX, y: rect.minY + bottomRight.height)
        let G = CGPoint(x: rect.maxX - bottomRight.width, y: rect.minY)
        let H = CGPoint(x: rect.minX + bottomLeft.width, y: rect.minY)
        // https://pomax.github.io/bezierinfo/#circles_cubic
        let const: CGFloat = 0.552_28

        let path = UIBezierPath()
        path.move(to: A)

        path.addLine(to: B)
        // TODO: @qhy find ellipse algorithm
        if topLeft.width == topLeft.height {
            let offset = const * topLeft.width
            path.addCurve(
                to: C,
                controlPoint1: CGPoint(x: B.x, y: B.y + offset),
                controlPoint2: CGPoint(x: C.x - offset, y: C.y)
            )
        } else {
            path.addQuadCurve(to: C, controlPoint: CGPoint(x: rect.minX, y: rect.maxY))
        }

        path.addLine(to: D)
        if topRight.width == topRight.height {
            let offset = const * topRight.width
            path.addCurve(
                to: E,
                controlPoint1: CGPoint(x: D.x + offset, y: D.y),
                controlPoint2: CGPoint(x: E.x, y: E.y + offset)
            )
        } else {
            path.addQuadCurve(to: E, controlPoint: CGPoint(x: rect.maxX, y: rect.maxY))
        }

        path.addLine(to: F)
        if bottomRight.width == bottomRight.height {
            let offset = const * bottomRight.width
            path.addCurve(
                to: G,
                controlPoint1: CGPoint(x: F.x, y: F.y - offset),
                controlPoint2: CGPoint(x: G.x + offset, y: G.y)
            )
        } else {
            path.addQuadCurve(to: G, controlPoint: CGPoint(x: rect.maxX, y: rect.minY))
        }

        path.addLine(to: H)
        if bottomLeft.width == bottomLeft.height {
            let offset = const * bottomLeft.width
            path.addCurve(
                to: A,
                controlPoint1: CGPoint(x: H.x - offset, y: H.y),
                controlPoint2: CGPoint(x: A.x, y: A.y - offset)
            )
        } else {
            path.addQuadCurve(to: A, controlPoint: CGPoint(x: rect.minX, y: rect.minY))
        }

        path.close()
        return path.cgPath
    }

    /// CoreText coordinate, origin is bottom-left corner.
    /// A B C D E F G H 8 points to calculate border path.
    /// step 1.
    ///     Connecting A B C
    /// step 2.
    ///     Connecting C D E
    /// step 3.
    ///     Connecting E F G
    /// step 4.
    ///     Connecting G H A
    /// step 5
    ///     Connecting a h g
    /// step 6
    ///     Connecting g f e
    /// step 7
    ///     Connecting e d c
    /// step 8
    ///     Connecting c b a
    /// C1---C---D---C2
    /// | c1-c---d-c2 |
    /// B b         e E
    /// | |         | |
    /// A a         f F
    /// |-c4-h---g-c3 |
    /// C4---H---G---C3
    private static func drawBorders(paintInfo: PaintInfo,
                                    border: Border,
                                    borderRadius: BorderRadius?,
                                    fontSize: CGFloat,
                                    rect: CGRect) {
        let topLeft = getActualLengthSize(borderRadius?.topLeft, fontSize: fontSize, rect: rect)
        let topRight = getActualLengthSize(borderRadius?.topRight, fontSize: fontSize, rect: rect)
        let bottomRight = getActualLengthSize(borderRadius?.bottomRight, fontSize: fontSize, rect: rect)
        let bottomLeft = getActualLengthSize(borderRadius?.bottomLeft, fontSize: fontSize, rect: rect)
        var borderEdges = [BorderEdgeRenderModel?](repeating: nil, count: 4)

        /// create border left renderer
        if let edge = border.left,
            edge.color.cgColor.alpha > 0.1,
            edge.color.hashValue != UIColor.clear.hashValue,
            let width = getBorderWidth(borderEdge: edge, fontSize: fontSize) {
            borderEdges[0] = BorderEdgeRenderModel(
                a: CGPoint(x: rect.minX - width, y: rect.minY + bottomLeft.height), // A
                b: CGPoint(x: rect.minX - width, y: rect.maxY - topLeft.height), // B
                c: CGPoint(x: rect.minX, y: rect.maxY - topLeft.height), // b
                d: CGPoint(x: rect.minX, y: rect.minY + bottomLeft.height), // a
                edge.color,
                edge.style
            )
        }
        /// create border top renderer
        if let edge = border.top,
            edge.color.cgColor.alpha > 0.1,
            edge.color.hashValue != UIColor.clear.hashValue,
            let width = getBorderWidth(borderEdge: edge, fontSize: fontSize) {
            borderEdges[1] = BorderEdgeRenderModel(
                a: CGPoint(x: rect.minX + topLeft.width, y: rect.maxY + width), // C
                b: CGPoint(x: rect.maxX - topRight.width, y: rect.maxY + width), // D
                c: CGPoint(x: rect.maxX - topRight.width, y: rect.maxY), // d
                d: CGPoint(x: rect.minX + topLeft.width, y: rect.maxY), // c
                edge.color,
                edge.style
            )
        }
        /// create border right renderer
        if let edge = border.right,
            edge.color.cgColor.alpha > 0.1,
            edge.color.hashValue != UIColor.clear.hashValue,
            let width = getBorderWidth(borderEdge: edge, fontSize: fontSize) {
            borderEdges[2] = BorderEdgeRenderModel(
                a: CGPoint(x: rect.maxX + width, y: rect.maxY - topRight.height), // E
                b: CGPoint(x: rect.maxX + width, y: rect.minY + bottomRight.height), // F
                c: CGPoint(x: rect.maxX, y: rect.minY + bottomRight.height), // f
                d: CGPoint(x: rect.maxX, y: rect.maxY - topRight.height), // e
                edge.color,
                edge.style
            )
        }
        /// create border bottom renderer
        if let edge = border.bottom,
            edge.color.cgColor.alpha > 0.1,
            edge.color.hashValue != UIColor.clear.hashValue,
            let width = getBorderWidth(borderEdge: edge, fontSize: fontSize) {
            let h = CGPoint(x: rect.minX + bottomLeft.width, y: rect.minY)
            let H = CGPoint(x: rect.minX + bottomLeft.width, y: rect.minY - width)
            let G = CGPoint(x: rect.maxX - bottomRight.width, y: rect.minY - width)
            let g = CGPoint(x: rect.maxX - bottomRight.width, y: rect.minY)
            borderEdges[3] = BorderEdgeRenderModel(a: G, b: H, c: h, d: g, edge.color, edge.style)
            borderEdges[3]?.dashLineInfo = .init(
                startPoint: .init(x: h.x, y: (h.y + H.y) / 2),
                endPoint: .init(x: G.x, y: (G.y + g.y) / 2),
                lineWidth: abs(H.y - h.y)
            )
        }
        var radiusEdges = [BorderEdgeRadiusRenderModel?](repeating: nil, count: 4)
        /// create bottom-left radius renderer
        if let left = borderEdges[0], let bottom = borderEdges[3] {
            if bottomLeft == .zero {
                borderEdges[0]?.a.y = bottom.a.y
                borderEdges[3]?.b.x = left.a.x
            } else {
                radiusEdges[0] = BorderEdgeRadiusRenderModel(
                    a: left.a, b: bottom.b, c1: CGPoint(x: left.a.x, y: bottom.b.y),
                    c: bottom.c, d: left.d, c2: CGPoint(x: left.d.x, y: bottom.c.y),
                left.color == bottom.color
                        ? [left.color]
                        : [left.color, bottom.color]
                )
            }
        }
        /// create top-left radius renderer
        if let left = borderEdges[0], let top = borderEdges[1] {
            if topLeft == .zero {
                borderEdges[0]?.b.y = top.a.y
                borderEdges[1]?.a.x = left.b.x
            } else {
                radiusEdges[1] = BorderEdgeRadiusRenderModel(
                    a: left.b, b: top.a, c1: CGPoint(x: left.b.x, y: top.a.y),
                    c: top.d, d: left.c, c2: CGPoint(x: left.c.x, y: top.d.y),
                    left.color == top.color
                        ? [left.color]
                        : [left.color, top.color]
                )
            }
        }
        /// create top-right radius renderer
        if let top = borderEdges[1], let right = borderEdges[2] {
            if topRight == .zero {
                borderEdges[1]?.b.x = right.a.x
                borderEdges[2]?.a.y = top.b.y
            } else {
                radiusEdges[2] = BorderEdgeRadiusRenderModel(
                    a: right.a, b: top.b, c1: CGPoint(x: right.a.x, y: top.b.y),
                    c: top.c, d: right.d, c2: CGPoint(x: right.d.x, y: top.c.y),
                    top.color == right.color
                        ? [top.color]
                        : [right.color, top.color]
                )
            }
        }
        /// create bottom-right radius renderer
        if let right = borderEdges[2], let bottom = borderEdges[3] {
            if bottomRight == .zero {
                borderEdges[2]?.b.y = bottom.a.y
                borderEdges[3]?.a.x = right.b.x
            } else {
                radiusEdges[3] = BorderEdgeRadiusRenderModel(
                    a: right.b, b: bottom.a, c1: CGPoint(x: right.b.x, y: bottom.a.y),
                    c: bottom.d, d: right.c, c2: CGPoint(x: right.c.x, y: bottom.d.y),
                    right.color == bottom.color
                        ? [right.color]
                        : [right.color, bottom.color]
                )
            }
        }
        /// render
        for edge in borderEdges {
            edge?.draw(paintInfo: paintInfo)
        }
        for radius in radiusEdges {
            radius?.draw(paintInfo: paintInfo)
        }
    }
}

private func getBorderWidth(borderEdge: BorderEdge, fontSize: CGFloat) -> CGFloat? {
    guard borderEdge.style != .none else {
        return nil
    }
    let borderWidth: CGFloat
    switch borderEdge.width {
    case .percent:
        return nil
    case .em(let em):
        borderWidth = em * fontSize
    case .point(let value):
        borderWidth = value
    }
    if borderWidth > 0 {
        return borderWidth
    }
    return nil
}

/// Can not greater than half of rect.width and rect.height
private func getActualLengthSize(_ value: LengthSize?, fontSize: CGFloat, rect: CGRect) -> CGSize {
    guard let wNumberic = value?.width, let hNumberic = value?.height else {
        return .zero
    }
    return CGSize(width: getActualValue(wNumberic, fontSize: fontSize, container: rect.width / 2), height: getActualValue(hNumberic, fontSize: fontSize, container: rect.height / 2))
}

@inline(__always)
private func getActualValue(_ numberic: NumbericValue, fontSize: CGFloat, container: CGFloat) -> CGFloat {
    switch numberic {
    case .em(let em):
        return min(em * fontSize, container)
    case .point(let value):
        return min(value, container)
    case .percent(let percent):
        return percent < 100 ? container * percent / 100 : container
    }
}
