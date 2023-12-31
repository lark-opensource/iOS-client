//
//  LKTextDrawAt.swift
//  LarkUIKit
//
//  Created by 齐鸿烨 on 2017/8/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

protocol LKTextDrawAt: AnyObject {
    var attachmentFrames: [CGRect] { get set }

    var textRect: CGRect { get }

    var postRenderQueue: [(CGContext) -> Void] { get set }

    func drawAt(runs: [LKTextRun], context: CGContext) -> [LKTextRun]

    func _drawAt(run: LKTextRun, context: CGContext)
}

extension LKTextDrawAt {
    func drawAt(runs: [LKTextRun], context: CGContext) -> [LKTextRun] {
        if runs.isEmpty {
            return []
        }
        var exceptRuns: [LKTextRun] = []
        for run in runs {
            if run.attributes[LKAtBackgroungColorAttributeName] != nil {
                _drawAt(run: run, context: context)
            } else {
                exceptRuns.append(run)
            }
        }

        return exceptRuns
    }

    func _drawAt(run: LKTextRun, context: CGContext) {
        let attributes = run.attributes
        if let backgroundColor = (attributes[LKAtBackgroungColorAttributeName] as? UIColor),
            let atAttrStr = attributes[LKAtStrAttributeName] as? NSAttributedString {
            // 相对于CTFrame的坐标系
            let tp = context.textPosition

            // 绘制背景
            let maxBackgroundWidth = self.textRect.size.width - run.origin.x
            let backgroundRect = CGRect(
                origin: CGPoint(x: tp.x + run.origin.x, y: tp.y - run.descent - run.leading),
                size: CGSize(width: min(maxBackgroundWidth, run.frame.size.width), height: run.frame.size.height)
            )
            let bezierPath = UIBezierPath(roundedRect: backgroundRect, cornerRadius: backgroundRect.height / 2)
            // 坐标系反转，再存储位置
            let optionsRect = CGRect(
                x: backgroundRect.minX,
                y: textRect.height + textRect.minY - run.origin.y - tp.y - run.ascent,
                width: backgroundRect.width,
                height: backgroundRect.height)
            self.attachmentFrames.append(optionsRect)
            context.saveGState()
            context.setFillColor(backgroundColor.cgColor)
            context.setStrokeColor(backgroundColor.cgColor)
            context.addPath(bezierPath.cgPath)
            context.fillPath(using: .winding)
            context.strokePath()

            // 绘制内容 得到内容应该绘制的区域，会剪切掉创建runDelegate时多加的高&&宽
            let originTextHeight = run.frame.size.height - 2
            let originTextWidth = run.frame.size.width - (originTextHeight - run.leading) / 2
            let originTextRect = CGRect(
                origin: CGPoint(x: backgroundRect.origin.x + originTextHeight / 4, y: backgroundRect.origin.y + 1),
                size: CGSize(width: originTextWidth, height: originTextHeight)
            )
            context.textPosition = originTextRect.origin
            context.textPosition.y += (run.descent + run.leading - 1)
            // 如果内容绘制不下，则需要特殊处理
            let maxContentWidth = self.textRect.size.width - run.origin.x - originTextHeight / 2
            if originTextRect.size.width > maxContentWidth {
                // setup more attributedString
                let moreAttr = NSMutableAttributedString(string: "\u{2026}")
                atAttrStr.enumerateAttributes(in: NSRange(location: 0, length: 1), options: .longestEffectiveRangeNotRequired) { (attrs, _, _) in
                    moreAttr.setAttributes(attrs, range: NSRange(location: 0, length: moreAttr.length))
                    return
                }
                self.drawTooLongText(maxWidth: maxContentWidth, atAttrStr: atAttrStr, moreAttr: moreAttr, context: context)
            } else {
                CTLineDraw(CTLineCreateWithAttributedString(atAttrStr), context)
            }

            // reset textPosition
            context.textPosition = tp
            context.restoreGState()
        }
    }

    private func drawTooLongText(maxWidth: CGFloat, atAttrStr: NSAttributedString, moreAttr: NSAttributedString, context: CGContext) {
        // 需要绘制的内容，可能绘制不完
        let atAttrStrLine = LKTextLine(line: CTLineCreateWithAttributedString(atAttrStr))
        // more内容，会绘制到最后
        let moreAttrLine = LKTextLine(line: CTLineCreateWithAttributedString(moreAttr))
        // 还剩下多少宽度绘制atAttrStrLine
        let expectLastLineWidth = maxWidth - moreAttrLine.width

        // 能被完整绘制的run总共多宽
        var allVisiableRunWidth: CGFloat = 0
        // 哪个index开始的run不能被完整绘制
        var maxVisiableRunIndex: Int = -1
        for i in 0..<atAttrStrLine.runs.count {
            if atAttrStrLine.runs[i].frame.maxX > expectLastLineWidth {
                maxVisiableRunIndex = i
                break
            }
            allVisiableRunWidth = atAttrStrLine.runs[i].frame.maxX
            // 绘制该run
            atAttrStrLine.runs[i].draw(context: context)
        }
        // 如果所有的run都能绘制，直接绘制more
        if maxVisiableRunIndex == -1 {
            context.textPosition.x += allVisiableRunWidth
            CTLineDraw(moreAttrLine.line, context)
            return
        }

        // 倒序判断哪个index前的glyph能被完整绘制，不包括index
        var maxVisiableGlyphIndex: Int = 0
        let glyphPoints = atAttrStrLine.runs[maxVisiableRunIndex].glyphPoints
        var targetIndex: Int = glyphPoints.count - 1
        while targetIndex >= 1 {
            if glyphPoints[targetIndex].x <= expectLastLineWidth {
                maxVisiableGlyphIndex = targetIndex
                allVisiableRunWidth = glyphPoints[targetIndex].x
                break
            }
            targetIndex -= 1
        }
        // 绘制glyph
        if maxVisiableGlyphIndex != 0 {
            atAttrStrLine.runs[maxVisiableRunIndex].draw(context: context, range: CFRange(location: 0, length: maxVisiableGlyphIndex))
        }
        // 绘制more
        context.textPosition.x += allVisiableRunWidth
        CTLineDraw(moreAttrLine.line, context)
    }
}
