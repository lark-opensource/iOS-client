//
//  LKTextDrawStrikeThrough.swift
//  RichLabel
//
//  Created by qihongye on 2019/8/7.
//

import UIKit
import Foundation

// @available(*, deprecated, message: "Use LKTextDrawLine")
protocol LKTextDrawStrikeThrough {
    func drawStrikeThrough(runs: [LKTextRun], context: CGContext) -> [LKTextRun]
    func _drawStrikeThrough(run: LKTextRun, context: CGContext)
}

extension LKTextDrawStrikeThrough {
    func drawStrikeThrough(runs: [LKTextRun], context: CGContext) -> [LKTextRun] {
        if runs.isEmpty {
            return []
        }
        for run in runs where run.attributes[NSAttributedString.Key.strikethroughStyle] != nil
            && run.attributes[NSAttributedString.Key.strikethroughColor] != nil {
            _drawStrikeThrough(run: run, context: context)
        }

        return runs
    }

    func _drawStrikeThrough(run: LKTextRun, context: CGContext) {
        guard let attributes = run.attributes as? [NSAttributedString.Key: Any],
            let strikethroughStyleNumber = attributes[.strikethroughStyle] as? NSNumber,
            let strikethroughColor = attributes[.strikethroughColor] as? UIColor else {
                return
        }
        let strikethroughStyle = NSUnderlineStyle(rawValue: strikethroughStyleNumber.intValue)
        var lineWidth: CGFloat = 0
        if strikethroughStyle.contains(.single) {
            lineWidth = 1
        }
        if strikethroughStyle.contains(.thick) {
            lineWidth = 2
        }
        if lineWidth == 0 {
            return
        }

        let pt = context.textPosition
        let strikeY = pt.y + run.origin.y - run.descent + run.frame.height * 0.5
        // start draw line
        context.saveGState()
        context.beginPath()
        context.setLineWidth(lineWidth)
        context.setStrokeColor(strikethroughColor.cgColor)
        context.move(to: CGPoint(x: pt.x + run.origin.x,
                                 y: strikeY))
        context.addLine(to: CGPoint(x: pt.x + run.origin.x + run.width,
                                    y: strikeY))
        context.strokePath()
        context.restoreGState()
    }
}
