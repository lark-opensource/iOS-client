//
//  ImageEditMosaicBezierPath.swift
//  LarkUIKit
//
//  Created by SuPeng on 12/19/18.
//

import UIKit
import Foundation

final class ImageEditMosaicBezierPath: UIBezierPath {
    let mosaicType: MosaicType
    let selectionType: SelectionType
    var scale: CGFloat
    var isHighlighted: Bool
    private(set) var points: [CGPoint] = []

    init(mosaicType: MosaicType, selectionType: SelectionType, scale: CGFloat = 1.0) {
        self.mosaicType = mosaicType
        self.selectionType = selectionType
        self.scale = scale
        self.isHighlighted = (selectionType == .area)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func add(point: CGPoint) {
        if selectionType == .point {
            if points.isEmpty {
                move(to: point)
            } else {
                addLine(to: point)
            }
        }

        points.append(point)

        if selectionType == .area {
            if let rect = getRect() {
                removeAllPoints()
                append(UIBezierPath(rect: rect))
            }
        }
    }

    func getRect() -> CGRect? {
        guard points.count > 1,
              let start = points.first,
              let end = points.last else {
            return nil
        }

        return CGRect(x: min(start.x, end.x),
                      y: min(start.y, end.y),
                      width: abs(start.x - end.x),
                      height: abs(start.y - end.y))
    }

    func getRemoveButtonFrame() -> CGRect {
        if let topLeftPoint = getRect()?.origin {
            return CGRect(x: topLeftPoint.x - 24 / scale,
                          y: topLeftPoint.y - 24 / scale,
                          width: 48 / scale,
                          height: 48 / scale)
        } else {
            return CGRect()
        }
    }

    func getRemoveButtonEdgeInsets() -> UIEdgeInsets {
        let inset = 10 / scale
        return UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    }

    func drawHighlightedBox() {
        // White border
        UIColor.white.set()
        lineWidth = 3.0 / scale
        stroke()

        // Corner points
        if let cornerPoints = getCornerPoints() {
            for point in cornerPoints {
                let outerCircle = UIBezierPath(arcCenter: point,
                                               radius: 5.0 / scale,
                                               startAngle: CGFloat(0),
                                               endAngle: CGFloat.pi * 2,
                                               clockwise: true)
                UIColor.white.set()
                outerCircle.fill()

                let innerCircle = UIBezierPath(arcCenter: point,
                                               radius: 3.0 / scale,
                                               startAngle: CGFloat(0),
                                               endAngle: CGFloat.pi * 2,
                                               clockwise: true)
                UIColor.ud.colorfulBlue.set()
                innerCircle.fill()
            }
        }
    }

    private func getCornerPoints() -> [CGPoint]? {
        if let rect = getRect() {
            var cornerPoints = [CGPoint]()
            let origin = rect.origin
            let xDirections: [CGFloat] = [0, 0.5, 1, 0, 1, 0, 0.5, 1]
            let yDirections: [CGFloat] = [0, 0, 0, 0.5, 0.5, 1, 1, 1]
            for i in 0..<xDirections.count {
                let point = CGPoint(x: origin.x + xDirections[i] * rect.width,
                                y: origin.y + yDirections[i] * rect.height)
                cornerPoints.append(point)
            }
            return cornerPoints
        }
        return nil
    }
}
