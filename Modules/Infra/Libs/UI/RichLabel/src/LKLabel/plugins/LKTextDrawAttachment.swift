//
//  LKTextDrawAttachment.swift
//  LarkUIKit
//
//  Created by 齐鸿烨 on 2017/8/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

protocol LKTextDrawAttachment: AnyObject {
    var view: UIView? { get set }

    // 存放各个attachment的frame，是相对于系统位置，在重新绘制的时候会被清空
    var attachmentFrames: [CGRect] { get set }

    var textRect: CGRect { get }

    func drawAttachment(runs: [LKTextRun], context: CGContext) -> [LKTextRun]

    func _drawAttachment(run: LKTextRun, context: CGContext)
}

extension LKTextDrawAttachment {
    func drawAttachment(runs: [LKTextRun], context: CGContext) -> [LKTextRun] {
        if runs.isEmpty {
            return []
        }

        for run in runs where run.attributes[LKAttachmentAttributeName] != nil {
            self._drawAttachment(run: run, context: context)
        }

        return runs
    }

    func _drawAttachment(run: LKTextRun, context: CGContext) {
        guard let attachment = run.attributes[LKAttachmentAttributeName] as? LKAttachmentProtocol else {
            return
        }

        let pt = context.textPosition
        let origin = run.origin
        let ascent = run.ascent

        if let view = self.view {
            view.addSubview(attachment.view)
            attachment.view.frame.origin = CGPoint(
                x: pt.x + origin.x + attachment.margin.left,
                y: textRect.height + textRect.minY - pt.y - origin.y - ascent + attachment.margin.top
            )
            attachmentFrames.append(attachment.view.frame)
        }
    }
}

protocol LKTextDrawGlyphTransform: AnyObject {
    func drawGlyphTrasform(runs: [LKTextRun], context: CGContext) -> [LKTextRun]

    func _drawGlyphTransform(run: LKTextRun, context: CGContext) -> Bool
}

extension LKTextDrawGlyphTransform {
    func drawGlyphTrasform(runs: [LKTextRun], context: CGContext) -> [LKTextRun] {
        if runs.isEmpty {
            return []
        }

        var exceptRuns: [LKTextRun] = []
        for run in runs where !self._drawGlyphTransform(run: run, context: context) {
            exceptRuns.append(run)
        }
        return exceptRuns
    }

    func _drawGlyphTransform(run: LKTextRun, context: CGContext) -> Bool {
        guard let value = run.attributes[LKGlyphTransformAttributeName] as? NSValue else {
            return false
        }

        let origin = context.textPosition
        let originTextMatrix = context.textMatrix

        context.saveGState()
        context.saveGState()
        context.textMatrix = .identity
        context.textMatrix = value.cgAffineTransformValue
        context.textPosition = origin
        run.draw(context: context)
        context.restoreGState()
        context.textMatrix = originTextMatrix
        context.restoreGState()
        return true
    }
}
