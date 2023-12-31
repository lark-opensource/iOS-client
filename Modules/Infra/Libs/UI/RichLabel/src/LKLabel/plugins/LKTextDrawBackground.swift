//
//  LKTextDrawBackground.swift
//  LarkUIKit
//
//  Created by 齐鸿烨 on 2017/8/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

protocol LKTextDrawBackground: AnyObject {
    func drawBackground(runs: [LKTextRun], context: CGContext) -> [LKTextRun]

    func _drawBackground(runs: [LKTextRun], attributes: NSDictionary, context: CGContext)

    func isBackgroundAttrEqual(_ lhs: NSDictionary, _ rhs: NSDictionary) -> Bool
}

extension LKTextDrawBackground {
    func drawBackground(runs: [LKTextRun], context: CGContext) -> [LKTextRun] {
        if runs.isEmpty {
            return []
        }
        var bgRuns: [LKTextRun] = []
        var bgAttributes = NSMutableDictionary()
        var exceptRuns: [LKTextRun] = []
        for run in runs {
            if run.attributes[LKBackgroundColorAttributeName] != nil &&
                (bgAttributes.allKeys.isEmpty ||
                    self.isBackgroundAttrEqual(bgAttributes, run.attributes)) {
                // 如果run连续了，则一起处理
                bgRuns.append(run)
                if bgAttributes.allKeys.isEmpty {
                    bgAttributes = NSMutableDictionary(dictionary: run.attributes)
                }
            } else {
                if !bgRuns.isEmpty {
                    self._drawBackground(runs: bgRuns, attributes: bgAttributes, context: context)
                }
                bgRuns = []
                bgAttributes.removeAllObjects()
                exceptRuns.append(run)
            }
        }
        _drawBackground(runs: bgRuns, attributes: bgAttributes, context: context)

        return exceptRuns
    }

    func _drawBackground(runs: [LKTextRun], attributes: NSDictionary, context: CGContext) {
        if runs.isEmpty {
            return
        }

        let backgroundColor = attributes[LKBackgroundColorAttributeName]
        let padding = (attributes[LKPaddingInsectAttributeName] as? UIEdgeInsets) ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let cornerRadius = CGFloat((attributes[LKCornerRadiusAttributeName] as? NSNumber)?.floatValue ?? 0)
        guard let color = backgroundColor else {
            return
        }

        // CoreText坐标系为左下角，所以x取最大y取最0
        var wrapperOrigin = CGPoint(x: CGFloat.greatestFiniteMagnitude, y: 0)
        var wrapperHeight: CGFloat = 0
        var wrapperDescent: CGFloat = 0
        var wrapperWidth: CGFloat = 0

        for run in runs {
            wrapperWidth += run.width
            if run.origin.x < wrapperOrigin.x {
                wrapperOrigin.x = run.origin.x
            }
            if run.origin.y > wrapperOrigin.y {
                wrapperOrigin.y = run.origin.y
            }
            if wrapperDescent < run.descent {
                wrapperDescent = run.descent
            }
            let height = run.ascent + run.descent + run.leading
            if wrapperHeight < height {
                wrapperHeight = height
            }
        }

        let pt = context.textPosition

        let rect = CGRect(x: wrapperOrigin.x + pt.x,
                          y: wrapperOrigin.y + pt.y - wrapperDescent,
                          width: CGFloat(wrapperWidth),
                          height: wrapperHeight).inset(by: padding)
        let bezierPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)

        let cgColor = (color as? UIColor ?? UIColor.clear).cgColor

        context.saveGState()
        context.setFillColor(cgColor)
        context.setStrokeColor(cgColor)
        context.addPath(bezierPath.cgPath)
        context.fillPath(using: .winding)
        context.strokePath()
        context.restoreGState()

        for run in runs {
            run.draw(context: context)
        }
    }

    func isBackgroundAttrEqual(_ lhs: NSDictionary, _ rhs: NSDictionary) -> Bool {
        guard let lcolor = lhs[LKBackgroundColorAttributeName] as? UIColor,
            let rcolor = rhs[LKBackgroundColorAttributeName] as? UIColor
            else {
                return false
        }
        if lcolor != rcolor {
            return false
        }
        if lhs[LKPaddingInsectAttributeName] as? UIEdgeInsets != rhs[LKPaddingInsectAttributeName] as? UIEdgeInsets {
            return false
        }
        if lhs[LKCornerRadiusAttributeName] as? NSNumber != rhs[LKCornerRadiusAttributeName] as? NSNumber {
            return false
        }
        return true
    }
}
