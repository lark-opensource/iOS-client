//
//  CountDownCircleLayer.swift
//  Calendar
//
//  Created by harry zou on 2019/4/15.
//

import UIKit
import CalendarFoundation
final class CountDownCircleLayer: CAShapeLayer {
    let startColor: UIColor
    let endColor: UIColor
    let endAngle: CGFloat
    let outerRedius: CGFloat
    let isLastSecond: Bool
    let size: CGSize
    weak var bindToView: UIView?

    init(startColor: UIColor,
         endColor: UIColor,
         endAngle: CGFloat,
         outerRedius: CGFloat,
         lineWidth: CGFloat,
         isLastSecond: Bool,
         size: CGSize,
         bindTo: UIView?) {
        self.startColor = startColor
        self.endColor = endColor
        self.endAngle = endAngle
        self.outerRedius = outerRedius
        self.isLastSecond = isLastSecond
        self.bindToView = bindTo
        self.size = size
        super.init()
        self.lineWidth = lineWidth
        addArc()
    }

    func addArc() {
        guard self.size != .zero else { return }

        let layer = CAShapeLayer()
        layer.frame = CGRect(origin: .zero, size: size)
        layer.ud.setBackgroundColor(UIColor.clear, bindTo: bindToView)
        addSublayer(layer)
        let path = UIBezierPath()

        UIGraphicsBeginImageContext(self.size)
        path.addArc(withCenter: CGPoint(x: outerRedius, y: outerRedius),
                    radius: outerRedius - lineWidth / 2,
                    startAngle: CGFloat.pi * 3 / 2,
                    endAngle: endAngle,
                    clockwise: false)
        path.stroke()
        UIGraphicsEndImageContext()
        layer.path = path.cgPath
        layer.ud.setFillColor(UIColor.clear, bindTo: bindToView)
        layer.ud.setStrokeColor(UIColor.ud.primaryOnPrimaryFill, bindTo: bindToView)
        layer.lineWidth = lineWidth
        layer.lineCap = .butt
        drawEndPointCircle(endPoint: path.currentPoint)
    }

    func drawEndPointCircle(endPoint: CGPoint) {
        guard self.size != .zero else { return }
        
        let layer = CAShapeLayer()
        layer.frame = CGRect(origin: .zero, size: size)
        layer.ud.setBackgroundColor(UIColor.clear, bindTo: bindToView)
        addSublayer(layer)
        let path = UIBezierPath()
        UIGraphicsBeginImageContext(self.size)
        let endAngle = isLastSecond ? CGFloat.pi * 1 / 2 : CGFloat.pi * -1 / 2
        path.addArc(withCenter: endPoint,
                    radius: lineWidth * 0.5 - 0.5,
                    startAngle: CGFloat.pi * 3 / 2,
                    endAngle: endAngle,
                    clockwise: false)
        path.stroke()
        UIGraphicsEndImageContext()
        layer.path = path.cgPath
        layer.ud.setFillColor(UIColor.ud.primaryOnPrimaryFill, bindTo: bindToView)
        layer.ud.setStrokeColor(UIColor.ud.primaryOnPrimaryFill, bindTo: bindToView)
        layer.lineWidth = 1
        layer.lineCap = .butt
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
