//
//  EditLayoutManager.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/9/2.
//

import UIKit
import Foundation

final class EditLayoutManager: NSLayoutManager {
    var useColor = UIColor.clear

    private var radius = CGFloat(8)
    private var maxIndex = 0
    private var extendWidth = CGFloat(10)
    private var rectArray: [CGRect] = []

    // swiftlint:disable function_body_length
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        guard let context = UIGraphicsGetCurrentContext() else { return }
        let glyphRange = glyphRange(forCharacterRange: characterRange(forGlyphRange: glyphsToShow,
                                                                      actualGlyphRange: nil),
                                    actualCharacterRange: nil)
        context.saveGState()
        context.translateBy(x: origin.x, y: origin.y)
        context.setBlendMode(.normal)

        useColor.setFill()
        useColor.setStroke()

        let path = UIBezierPath()
        rectArray.removeAll()

        enumerateLineFragments(forGlyphRange: glyphRange) { [weak self] _, usedRect, _, _, _ in
            guard let self = self else { return }
            self.rectArray.append(CGRect(x: usedRect.origin.x,
                                         y: usedRect.origin.y,
                                         width: usedRect.size.width,
                                         height: usedRect.size.height))
        }
        preprocess()

        rectArray.indices.forEach {
            let current = rectArray[$0]
            path.append(UIBezierPath(roundedRect: current, cornerRadius: radius))

            guard $0 > 0 else { return }
            let last = rectArray[$0 - 1]
            let currentLeft = current.origin
            let currentRight = CGPoint(x: current.maxX, y: current.minY)
            let lastLeft = CGPoint(x: last.minX, y: last.maxY)
            let lastRight = CGPoint(x: last.maxX, y: last.maxY)

            if currentLeft.x - lastLeft.x >= 2 * radius {
                let addPath = UIBezierPath(arcCenter: .init(x: currentLeft.x - radius, y: currentLeft.y + radius),
                                           radius: radius,
                                           startAngle: .pi / 2 * 3,
                                           endAngle: 0,
                                           clockwise: true)
                addPath.append(UIBezierPath(arcCenter: .init(x: currentLeft.x + radius, y: currentLeft.y + radius),
                                            radius: radius,
                                            startAngle: .pi,
                                            endAngle: .pi / 2 * 3,
                                            clockwise: true))
                addPath.addLine(to: .init(x: currentLeft.x - radius, y: currentLeft.y))
                path.append(addPath)
            } else if currentLeft.x == lastLeft.x {
                path.move(to: .init(x: currentLeft.x, y: currentLeft.y - radius))
                path.addLine(to: .init(x: currentLeft.x, y: currentLeft.y + radius))
                path.addArc(withCenter: .init(x: currentLeft.x + radius, y: currentLeft.y + radius),
                            radius: radius,
                            startAngle: .pi,
                            endAngle: .pi / 2 * 3,
                            clockwise: true)
                path.addArc(withCenter: .init(x: currentLeft.x + radius, y: currentLeft.y - radius),
                            radius: radius,
                            startAngle: .pi / 2,
                            endAngle: .pi,
                            clockwise: true)
            }

            if lastRight.x - currentRight.x >= 2 * radius {
                let addPath = UIBezierPath(arcCenter: .init(x: currentRight.x + radius, y: currentRight.y + radius),
                                           radius: radius,
                                           startAngle: .pi / 2 * 3,
                                           endAngle: .pi,
                                           clockwise: false)
                addPath.append(UIBezierPath(arcCenter: .init(x: currentRight.x - radius, y: currentRight.y + radius),
                                            radius: radius,
                                            startAngle: 0,
                                            endAngle: .pi / 2 * 3,
                                            clockwise: false))
                addPath.addLine(to: .init(x: currentRight.x + radius, y: currentRight.y))
                path.append(addPath)
            } else if lastRight.x == currentRight.x {
                path.move(to: .init(x: currentRight.x, y: currentRight.y - radius))
                path.addLine(to: .init(x: currentRight.x, y: currentRight.y + radius))
                path.addArc(withCenter: .init(x: currentRight.x - radius, y: currentRight.y + radius),
                            radius: radius,
                            startAngle: 0,
                            endAngle: .pi / 2 * 3,
                            clockwise: false)
                path.addArc(withCenter: .init(x: currentRight.x - radius, y: currentRight.y - radius),
                            radius: radius,
                            startAngle: .pi / 2,
                            endAngle: 0,
                            clockwise: false)
            }

            if lastLeft.x - currentLeft.x >= 2 * radius {
                let addPath = UIBezierPath(arcCenter: .init(x: lastLeft.x - radius, y: lastLeft.y - radius),
                                           radius: radius,
                                           startAngle: .pi / 2,
                                           endAngle: 0,
                                           clockwise: false)
                addPath.append(UIBezierPath(arcCenter: .init(x: lastLeft.x + radius, y: lastLeft.y - radius),
                                            radius: radius,
                                            startAngle: .pi,
                                            endAngle: .pi / 2,
                                            clockwise: false))
                addPath.addLine(to: .init(x: lastLeft.x - radius, y: lastLeft.y))
                path.append(addPath)
            }

            if currentRight.x - lastRight.x >= 2 * radius {
                let addPath = UIBezierPath(arcCenter: .init(x: lastRight.x + radius, y: lastRight.y - radius),
                                           radius: radius,
                                           startAngle: .pi / 2,
                                           endAngle: .pi,
                                           clockwise: true)
                addPath.append(UIBezierPath(arcCenter: .init(x: lastRight.x - radius, y: lastRight.y - radius),
                                            radius: radius,
                                            startAngle: 0,
                                            endAngle: .pi / 2,
                                            clockwise: true))
                addPath.addLine(to: .init(x: lastRight.x + radius, y: lastRight.y))
                path.append(addPath)
            }
        }
        path.stroke()
        path.fill()
        context.restoreGState()
    }
    // swiftlint:enable function_body_length

    private func preprocess() {
        guard let firstRect = rectArray.first else { return }
        rectArray[0] = .init(x: firstRect.minX,
                             y: firstRect.minY - extendWidth,
                             width: firstRect.width,
                             height: firstRect.height + extendWidth)

        guard let lastRect = rectArray.last else { return }
        rectArray[rectArray.count - 1] = .init(origin: lastRect.origin,
                                               size: .init(width: lastRect.width,
                                                           height: lastRect.height + extendWidth))

        rectArray.indices.forEach {
            maxIndex = $0 + 1
            preprocessRect(at: $0)
        }
    }

    // 对每一行的frame进行预处理，如果两个矩形之间比较接近，那么把这两个矩形设置成一样大，避免切出圆角
    private func preprocessRect(at index: Int) {
        guard index >= 1 && index < maxIndex else { return }
        let current = rectArray[index]
        let last = rectArray[index - 1]

        if (last.minX - current.minX < 2 * radius && last.minX > current.minX)
            || (last.maxX - current.maxX > -2 * radius && last.maxX < current.maxX) {
            let newRect = CGRect(x: current.origin.x, y: last.origin.y, width: current.size.width,
                                 height: last.size.height)
            rectArray[index - 1] = newRect
            preprocessRect(at: index - 1)
        }

        if (current.minX - last.minX < 2 * radius && current.minX > last.minX)
            || (current.maxX - last.maxX > -2 * radius && current.maxX < last.maxX) {
            let newRect = CGRect(x: last.origin.x, y: current.origin.y, width: last.size.width,
                                 height: current.size.height)
            rectArray[index] = newRect
            preprocessRect(at: index + 1)
        }
    }

    // textview里面的行数
    var numberOfLines: Int {
        var count = 0
        enumerateLineFragments(forGlyphRange: .init(location: 0, length: numberOfGlyphs)) { _, _, _, _, _ in
            count += 1
        }
        return count
    }
}
