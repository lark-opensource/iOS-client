//
//  TriangleView.swift
//  ByteViewTab
//
//  Created by kiri on 2021/8/17.
//

import Foundation

open class TriangleView: UIView {
    public var color: UIColor?
    public var direction: Direction = .top
    let defaultWidth: CGFloat = 20.0
    let defaultHeight: CGFloat = 9.0
    var realWidth: CGFloat { max(bounds.size.width, bounds.size.height) }
    var realHeight: CGFloat { min(bounds.size.width, bounds.size.height) }

    public override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        let path = UIBezierPath()
        plot(path: path)
        switch direction {
        case .top:
            break
        case .bottom, .centerBottom:
            ctx?.translateBy(x: realWidth, y: realHeight)
            ctx?.rotate(by: .pi)
        case .left:
            ctx?.translateBy(x: 0, y: realWidth)
            ctx?.rotate(by: -.pi / 2)
        case .right:
            ctx?.translateBy(x: realHeight, y: 0)
            ctx?.rotate(by: .pi / 2)
        }
        ctx?.addPath(path.cgPath)
        color?.setFill()
        ctx?.fillPath()
    }

    func plot(path: UIBezierPath) {
        let widthMultiple = realWidth / defaultWidth
        let heightMultiple = realHeight / defaultHeight

        let leftUpX: CGFloat = 5
        let leftUpY: CGFloat = 2.2
        let leftBottomX: CGFloat = 7.8
        let leftBottomY: CGFloat = 6

        let rightUpX: CGFloat = defaultWidth - leftUpX
        let rightUpY: CGFloat = leftUpY
        let rightBottomX: CGFloat = defaultWidth - leftBottomX
        let rightBottomY: CGFloat = leftBottomY

        let leftArcCtl1X: CGFloat = 3.5
        let leftArcCtl1Y: CGFloat = 0.0
        let leftArcCtl2X: CGFloat = 5
        let leftArcCtl2Y: CGFloat = 2.2

        let rightArcCtl1X: CGFloat = defaultWidth - leftArcCtl2X
        let rightArcCtl1Y: CGFloat = leftArcCtl2Y
        let rightArcCtl2X: CGFloat = defaultWidth - leftArcCtl1X
        let rightArcCtl2Y: CGFloat = leftArcCtl1Y

        let bottomArcCtl1X: CGFloat = 9
        let bottomArcCtl1Y: CGFloat = 7.8
        let bottomArcCtl2X: CGFloat = defaultWidth - bottomArcCtl1X
        let bottomArcCtl2Y: CGFloat = bottomArcCtl1Y

        path.move(to: CGPoint(x: 0, y: 0))
        path.addCurve(to: CGPoint(x: leftUpX * widthMultiple, y: leftUpY * heightMultiple),
                      controlPoint1: CGPoint(x: leftArcCtl1X * widthMultiple, y: leftArcCtl1Y * heightMultiple),
                      controlPoint2: CGPoint(x: leftArcCtl2X * widthMultiple, y: leftArcCtl2Y * heightMultiple))

        path.addLine(to: CGPoint(x: leftBottomX * widthMultiple, y: leftBottomY * heightMultiple))
        path.addCurve(to: CGPoint(x: rightBottomX * widthMultiple, y: rightBottomY * heightMultiple),
                      controlPoint1: CGPoint(x: bottomArcCtl1X * widthMultiple, y: bottomArcCtl1Y * heightMultiple),
                      controlPoint2: CGPoint(x: bottomArcCtl2X * widthMultiple, y: bottomArcCtl2Y * heightMultiple))

        path.addLine(to: CGPoint(x: rightUpX * widthMultiple, y: rightUpY * heightMultiple))
        path.addCurve(to: CGPoint(x: defaultWidth * widthMultiple, y: 0),
                      controlPoint1: CGPoint(x: rightArcCtl1X * widthMultiple, y: rightArcCtl1Y * heightMultiple),
                      controlPoint2: CGPoint(x: rightArcCtl2X * widthMultiple, y: rightArcCtl2Y * heightMultiple))
    }

    public enum Direction {
        case top
        case bottom
        case left
        case right
        case centerBottom
    }
}
