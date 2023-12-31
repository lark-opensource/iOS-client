//
//  LKTextDrawPoint.swift
//  LarkUIKit
//
//  Created by 齐鸿烨 on 2017/8/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import CoreText

protocol LKTextDrawPoint: AnyObject {
    var firstAtPointRect: CGRect? { get set }

    var fontSize: CGFloat { get }

    var view: UIView? { get set }

    var textRect: CGRect { get }

    var postRenderQueue: [(CGContext) -> Void] { get set }

    func drawPoint(runs: [LKTextRun], context: CGContext) -> [LKTextRun]

    func _drawPoint(run: LKTextRun, context: CGContext, pointRect: inout CGRect?)
}

extension LKTextDrawPoint {
    func drawPoint(runs: [LKTextRun], context: CGContext) -> [LKTextRun] {
        if runs.isEmpty {
            return []
        }

        var pointRect: CGRect?
        var exceptRuns: [LKTextRun] = []

        for run in runs {
            if run.attributes[LKPointAttributeName] != nil {
                self._drawPoint(run: run, context: context, pointRect: &pointRect)
            } else {
                exceptRuns.append(run)
            }

            self.firstAtPointRect = pointRect
        }

        return exceptRuns
    }

    func _drawPoint(run: LKTextRun, context: CGContext, pointRect: inout CGRect?) {
        guard let pointColor = (run.attributes[LKPointAttributeName] as? UIColor)?.cgColor,
            let char = (run.attributes[LKAtStrAttributeName] as? NSAttributedString) else {
                return
        }

        let textRect = self.textRect
        let pointRadius = (run.attributes[LKPointRadiusAttributeName] as? CGFloat) ?? (self.fontSize * 0.15)
        let pointInnerRadius = (run.attributes[LKPointInnerRadiusAttributeName] as? CGFloat) ?? 0

        let pt = context.textPosition
        let origin = run.origin
        let ascent = run.ascent
        let wrapperWidth = run.width
        let pointCenter = CGPoint(
            x: origin.x + pt.x + wrapperWidth - pointRadius,
            y: origin.y + pt.y + ascent - pointRadius
        )

        // 如果全都是英文，显示时上面溢出的半圆会无法展示
        let pointPath = UIBezierPath(
            arcCenter: pointCenter,
            radius: pointRadius,
            startAngle: 0,
            endAngle: 2 * CGFloat.pi,
            clockwise: true
        )
        pointRect = pointPath.bounds.applying(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: textRect.height))
        let drawPath = CGMutablePath()
        drawPath.addPath(pointPath.cgPath)

        if pointInnerRadius > 0 {
            drawPath.addPath(UIBezierPath(
                arcCenter: pointCenter,
                radius: pointInnerRadius,
                startAngle: 0,
                endAngle: 2 * CGFloat.pi,
                clockwise: false
            ).cgPath)
        }

        context.saveGState()
        context.setFillColor(pointColor)
        context.setStrokeColor(pointColor)
        context.addPath(drawPath)
        context.drawPath(using: CGPathDrawingMode.eoFill)
        context.strokePath()
        context.restoreGState()

        let value = char.string.unicodeScalars.map({ $0.value }).reduce(0, +)
        // [^a-zA-Z0-9]+
        if char.string.unicodeScalars.count > 1 ||
            !((value >= 0x30 && value <= 0x39) ||
                (value >= 0x61 && value <= 0x7a) ||
                (value >= 0x41 && value <= 0x5a)) {
            let line = CTLineCreateWithAttributedString(char)
            let runs = CTLineGetGlyphRuns(line) as? [CTRun] ?? []
            context.saveGState()
            context.textPosition.x = origin.x + pt.x
            for run in runs {
                CTRunDraw(run, context, CFRANGE_ZERO)
            }
            context.textPosition.x = pt.x
            context.restoreGState()
        } else {
            run.draw(context: context)
        }
    }
}
