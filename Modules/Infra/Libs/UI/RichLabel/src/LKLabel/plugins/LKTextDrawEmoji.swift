//
//  LKTextDrawEmoji.swift
//  LarkUIKit
//
//  Created by 齐鸿烨 on 2017/10/20.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

protocol LKTextDrawEmoji: AnyObject {
    var view: UIView? { get set }

    var textRect: CGRect { get }

    func drawEmoji(runs: [LKTextRun], context: CGContext) -> [LKTextRun]

    func _drawEmoji(run: LKTextRun, context: CGContext)
}

extension LKTextDrawEmoji {
    func drawEmoji(runs: [LKTextRun], context: CGContext) -> [LKTextRun] {
        if runs.isEmpty {
            return []
        }

        for run in runs where run.attributes[LKEmojiAttributeName] != nil {
            self._drawEmoji(run: run, context: context)
        }

        return runs
    }

    func _drawEmoji(run: LKTextRun, context: CGContext) {
        guard let emoji = run.attributes[LKEmojiAttributeName] as? LKEmoji else {
            return
        }

        let pt = context.textPosition
        let origin = run.origin
        let ascent = run.ascent

        var frame = emoji.drawFrame
        frame.origin.x += pt.x + origin.x
        frame.origin.y = textRect.height + textRect.origin.y - origin.y - pt.y - ascent

        context.saveGState()
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: -textRect.origin.x, y: -textRect.height - textRect.origin.y)
        emoji.icon.draw(in: frame)
        context.restoreGState()
    }
}
