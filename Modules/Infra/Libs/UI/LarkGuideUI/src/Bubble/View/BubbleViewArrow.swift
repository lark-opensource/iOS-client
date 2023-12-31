//
//  BubbleViewArrow.swift
//  LarkGuide
//
//  Created by zhenning on 2020/05/18.
//

import UIKit
import Foundation
extension BubbleViewArrow {
    enum Layout {
        // 箭头指向左右
        static let arrowHorizontalSize: CGSize = CGSize(width: 10.0, height: 24.0)
        // 箭头指向上下
        static let arrowVerticalSize: CGSize = CGSize(width: 24.0, height: 10.0)
    }
}

public final class BubbleViewArrow: UIView {

    public init() {
        super.init(frame: CGRect(origin: CGPoint.zero,
                                 size: Layout.arrowHorizontalSize))
        self.backgroundColor = UIColor.clear
    }

    private let path = UIBezierPath()

    override public class var layerClass: AnyClass {
        return CAShapeLayer.self
    }

    private var shapeLayer: CAShapeLayer {
        // swiftlint:disable:next force_cast
        return layer as! CAShapeLayer
    }

    var direction: BubbleArrowDirection = .left {
        didSet {
            updateCurrentDirection()
        }
    }

    var arrowColor: UIColor = UIColor.ud.primaryFillHover {
        didSet {
            shapeLayer.ud.setFillColor(arrowColor)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding.")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateCurrentDirection()
    }

    private func updateCurrentDirection() {
        path.removeAllPoints()
        switch direction {
        case .down:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addQuadCurve(to: CGPoint(x: 6.5, y: 3), controlPoint: CGPoint(x: 4, y: 0))
            path.addLine(to: CGPoint(x: 10.2, y: 8))
            path.addQuadCurve(to: CGPoint(x: 13.8, y: 8), controlPoint: CGPoint(x: 12, y: 10))
            path.addLine(to: CGPoint(x: 17.5, y: 3))
            path.addQuadCurve(to: CGPoint(x: 24, y: 0), controlPoint: CGPoint(x: 20, y: 0))
        case .up:
            path.move(to: CGPoint(x: 0, y: 10))
            path.addQuadCurve(to: CGPoint(x: 6.5, y: 7), controlPoint: CGPoint(x: 4, y: 10))
            path.addLine(to: CGPoint(x: 10.2, y: 2))
            path.addQuadCurve(to: CGPoint(x: 13.8, y: 2), controlPoint: CGPoint(x: 12, y: 0))
            path.addLine(to: CGPoint(x: 17.5, y: 7))
            path.addQuadCurve(to: CGPoint(x: 24, y: 10), controlPoint: CGPoint(x: 20, y: 10))
        case .left:
            path.move(to: CGPoint(x: 10, y: 0))
            path.addQuadCurve(to: CGPoint(x: 7, y: 6.5), controlPoint: CGPoint(x: 10, y: 4))
            path.addLine(to: CGPoint(x: 2, y: 10.2))
            path.addQuadCurve(to: CGPoint(x: 2, y: 13.8), controlPoint: CGPoint(x: 0, y: 12))
            path.addLine(to: CGPoint(x: 7, y: 17.5))
            path.addQuadCurve(to: CGPoint(x: 10, y: 24), controlPoint: CGPoint(x: 10, y: 20))
        case .right:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addQuadCurve(to: CGPoint(x: 3, y: 6.5), controlPoint: CGPoint(x: 0, y: 4))
            path.addLine(to: CGPoint(x: 8, y: 10.2))
            path.addQuadCurve(to: CGPoint(x: 8, y: 13.8), controlPoint: CGPoint(x: 10, y: 12))
            path.addLine(to: CGPoint(x: 3, y: 17.5))
            path.addQuadCurve(to: CGPoint(x: 0, y: 24), controlPoint: CGPoint(x: 0, y: 20))
        }
        path.close()
        shapeLayer.path = path.cgPath
    }
}
