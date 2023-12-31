//
//  EasyhintbubbleViewArrow.swift
//  LarkUIKit
//
//  Created by sniperj on 2018/12/7.
//

import UIKit
import Foundation

// NOTE: 1.19.0将arrowView暴露，暂时解决群公告需求问题
public final class EasyhintbubbleViewArrow: UIView {
    private let preference: Preferences

    public init(preference: Preferences) {
        self.preference = preference
        switch self.preference.drawing.arrowPosition {
        case .left, .right:
            super.init(frame: CGRect(x: 0,
                                     y: 0,
                                     width: self.preference.drawing.arrowHeight,
                                     height: self.preference.drawing.arrowWidth))
        case .top, .bottom:
            super.init(frame: CGRect(x: 0,
                                     y: 0,
                                     width: self.preference.drawing.arrowWidth,
                                     height: self.preference.drawing.arrowHeight))
        case .any:
            super.init(frame: CGRect(x: 0,
                                     y: 0,
                                     width: self.preference.drawing.arrowWidth,
                                     height: self.preference.drawing.arrowHeight))
        }
        self.backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding.")
    }

    public override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(self.preference.drawing.backgroundColor.cgColor)

        switch self.preference.drawing.arrowPosition {
        case .left:
            context?.move(to: CGPoint(x: CGFloat(sqrtf(8) / 2),
                                      y: self.bounds.size.height / 2 - CGFloat(sqrtf(8) / 2)))
            context?.addArc(tangent1End: CGPoint(x: 0,
                                                 y: self.bounds.height / 2),
                            tangent2End: CGPoint(x: CGFloat(sqrtf(8) / 2),
                                                 y: self.bounds.size.height / 2 + CGFloat(sqrtf(8) / 2)), radius: 2)
            context?.addLine(to: CGPoint(x: self.bounds.size.width, y: self.bounds.size.height))
            context?.addLine(to: CGPoint(x: self.bounds.size.width, y: 0))
        case .right:
            context?.move(to: CGPoint(x: 0, y: 0))
            context?.addLine(to: CGPoint(x: self.bounds.size.width - CGFloat(sqrtf(8) / 2),
                                         y: self.bounds.size.height / 2 - CGFloat(sqrtf(8) / 2)))
            context?.addArc(tangent1End: CGPoint(x: self.bounds.width,
                                                 y: self.bounds.height / 2),
                            tangent2End: CGPoint(x: self.bounds.size.width - CGFloat(sqrtf(8) / 2),
                                                 y: self.bounds.size.height / 2 + CGFloat(sqrtf(8) / 2)), radius: 2)
            context?.addLine(to: CGPoint(x: 0, y: self.bounds.size.height))
        case .top:
            context?.move(to: CGPoint(x: 0,
                                      y: self.bounds.size.height))
            context?.addLine(to: CGPoint(x: self.bounds.size.width / 2 - CGFloat(sqrtf(8) / 2),
                                         y: CGFloat(sqrtf(8) / 2)))
            context?.addArc(tangent1End: CGPoint(x: self.bounds.size.width / 2,
                                                 y: 0),
                            tangent2End: CGPoint(x: self.bounds.size.width / 2 + CGFloat(sqrtf(8) / 2),
                                                 y: CGFloat(sqrtf(8) / 2)),
                            radius: 2)
            context?.addLine(to: CGPoint(x: self.bounds.size.width, y: self.bounds.size.height))
        case .bottom:
            context?.move(to: CGPoint(x: 0, y: 0))
            context?.addLine(to: CGPoint(x: self.bounds.size.width / 2 - CGFloat(sqrtf(8) / 2),
                                         y: self.bounds.size.height - CGFloat(sqrtf(8) / 2)))
            context?.addArc(tangent1End: CGPoint(x: self.bounds.size.width / 2,
                                                 y: self.bounds.size.height),
                            tangent2End: CGPoint(x: self.bounds.size.width / 2 + CGFloat(sqrtf(8) / 2),
                                                 y: self.bounds.size.height - CGFloat(sqrtf(8) / 2)),
                            radius: 2)
            context?.addLine(to: CGPoint(x: self.bounds.size.width, y: 0))
        case .any:
            break
        }
        context?.closePath()
        context?.drawPath(using: .fill)
    }
}
