//
//  LKTextRenderEngine.swift
//  LarkUIKit
//
//  Created by 齐鸿烨 on 2017/8/28.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

public struct PointAtInTextIndex {
    var nearist: CFIndex
    var other: CFIndex
}

public protocol LKTextRenderEngine: AnyObject {
    var isFuzzyPointAt: Bool { get set }

    var fuzzyEdgeInsets: UIEdgeInsets { get set }

    var attributedText: NSAttributedString? { get set }

    var view: UIView? { get set }

    var font: UIFont { get set }

    var lineSpacing: CGFloat { get set }

    var attachmentFrames: [CGRect] { get set }

    var lines: [LKTextLine] { get set }

    /// 画布大小
    var bounds: CGRect { get set }

    /// 内容距离周围的边距
    var insetsRect: UIEdgeInsets { get set }

    /// 内容实际可以绘制范围，考虑了rect、insetsRect和textSize
    var textRect: CGRect { get }

    /// 内容大小
    var textSize: CGSize { get set }

    /// 垂直方向上对齐方式
    var textVerticalAlignment: LKTextVerticalAlignment { get set }

    var backgroundColor: UIColor? { get set }

    var numberOfLines: Int { get set }

    var outOfRangeTextLayout: LKTextLayoutEngine? { get set }
//    var outOfRangeText: NSAttributedString? { get set }

    var textColor: UIColor { get set }

    var textAlign: NSTextAlignment { get set }

    var visibleTextRange: NSRange? { get set }

    var isOutOfRange: Bool { get set }

    var lastLine: LKTextLine? { get }

    var postRenderQueue: [(CGContext) -> Void] { get set }

    func pointAt(_ point: CGPoint) -> PointAtInTextIndex

    func isPointAtOutOfRangeText(_ point: CGPoint) -> Bool

    func draw(line: LKTextLine, context: CGContext, debug: LKTextRenderDebugOptions?)

    func draw(context: CGContext, debug: LKTextRenderDebugOptions?)
}

public final class LKTextRenderEngineImpl: LKTextRenderEngine {
    public var attributedText: NSAttributedString? {
        didSet {
            postRenderQueue = []
            guard let attrStr = attributedText else {
                visibleTextRange = nil
                return
            }

            if oldValue == nil || attrStr.string != oldValue!.string {
                visibleTextRange = NSRange(location: 0, length: attrStr.length)
            }
        }
    }

    public var isFuzzyPointAt: Bool = false

    public var fuzzyEdgeInsets: UIEdgeInsets = .zero

    public var lineSpacing: CGFloat = 0

    public weak var view: UIView?

    public var attachmentFrames: [CGRect] = []

    public var font: UIFont = UIFont.systemFont(ofSize: 14)

    public var lines: [LKTextLine] = [] {
        didSet {
            // fix width
            let limitWidth = self.textRect.size.width
            self.lines.forEach { (textLine) in
                textLine.width = min(limitWidth, textLine.width)
                textLine.frame.size = CGSize(width: textLine.width, height: textLine.frame.size.height)
            }
            lastLine = lines.last
        }
    }

    public var numberOfLines: Int = 0

    /// 画布大小
    public var bounds: CGRect = .zero {
        didSet {
            if bounds == oldValue {
                return
            }
            needReCountTextRect = true
        }
    }

    /// 内容距离周围的边距
    public var insetsRect: UIEdgeInsets = .zero {
        didSet {
            if insetsRect == oldValue {
                return
            }
            needReCountTextRect = true
        }
    }

    /// 内容实际可以绘制范围，考虑了rect、insetsRect和textSize
    private var _textRect: CGRect = .zero
    private var needReCountTextRect: Bool = true
    public var textRect: CGRect {
        if needReCountTextRect == false {
            return _textRect
        }
        needReCountTextRect = false

        _textRect = self.bounds.inset(by: self.insetsRect)
        // 只在小于画布高度时修正origin.y，不会存在textSize.height大于_textRect.size.height的情况
        if abs(self.textSize.height - _textRect.size.height) > 0.2 {
            var yOffset: CGFloat = 0
            switch self.textVerticalAlignment {
            case .middle:
                yOffset = floor(CGFloat((_textRect.size.height - self.textSize.height) / 2))
            case .top:
                yOffset = 0
            case .bottom:
                yOffset = floor(CGFloat(_textRect.size.height - self.textSize.height))
            }
            _textRect.origin.y += yOffset
            _textRect.size.height = self.textSize.height
        }
        return _textRect
    }

    /// 实际内容大小，可能比画布大
    public var textSize: CGSize = .zero {
        didSet {
            if textSize == oldValue {
                return
            }
            needReCountTextRect = true
        }
    }

    /// 垂直方向上对齐方式
    public var textVerticalAlignment: LKTextVerticalAlignment = .middle {
        didSet {
            if textVerticalAlignment == oldValue {
                return
            }
            needReCountTextRect = true
        }
    }

    public var textColor: UIColor = .black

    public var textAlign: NSTextAlignment = .left

    public var backgroundColor: UIColor?

    public var visibleTextRange: NSRange?

    public var outOfRangeTextLayout: LKTextLayoutEngine?

    public var outOfRangeTextWidth: CGFloat {
        return outOfRangeTextLayout?.textSize.width ?? 0
    }

    public var isOutOfRange: Bool = false

    public var postRenderQueue: [(CGContext) -> Void] = []

    public private(set) var lastLine: LKTextLine?

    var firstAtPointRect: CGRect?

    public private(set) var outOfRangeTextRect: CGRect?

    public init(view: UIView) {
        self.view = view
    }

    public func checkIsOutOfRange() -> Bool {
        if isOutOfRange {
            return isOutOfRange
        }

        if attributedText == nil || lines.isEmpty {
            return false
        }

        if numberOfLines > 0 && lines.count < numberOfLines {
            return false
        }

        return lines.last!.range.length + lines.last!.range.location < attributedText!.length
    }

    public func draw(context: CGContext, debug: LKTextRenderDebugOptions? = nil) {
        context.saveGState()
        defer {
            context.restoreGState()
        }
        context.clear(textRect)

        if let bgColor = self.backgroundColor {
            context.setFillColor(bgColor.cgColor)
            context.fill(textRect)
        }

        if lines.isEmpty {
            lastLine = nil
            return
        }

        context.textMatrix = .identity
        context.translateBy(x: textRect.origin.x, y: textRect.height + textRect.origin.y)
        context.scaleBy(x: 1.0, y: -1.0)

        let linesCount = lines.count
        lastLine = lines.last!
        attachmentFrames = []

        DEBUG(true: {
            for index in 0 ..< linesCount - 1 {
                draw(line: self.lines[index], context: context, debug: debug)
            }
            draw(lastLine: self.lastLine!, context: context, debug: debug)
        }, false: {
            for index in 0 ..< linesCount - 1 {
                draw(line: self.lines[index], context: context)
            }
            draw(lastLine: self.lastLine!, context: context)
        })

        for render in postRenderQueue {
            render(context)
        }
    }

    public func draw(line: LKTextLine, context: CGContext, debug: LKTextRenderDebugOptions? = nil) {
        line.origin = lineXCorrection(lineOrigin: line.origin, lineWidth: line.width, textRect: textRect, alignment: textAlign)
        context.textPosition = line.origin
        DEBUG(true: {
            draw(runs: line.runs, line: line, context: context, debug: debug)
        }, false: {
            draw(runs: line.runs, line: line, context: context)
        })
    }

    private func draw(lastLine: LKTextLine, context: CGContext, debug: LKTextRenderDebugOptions? = nil) {
        if !checkIsOutOfRange() {
            draw(line: lastLine, context: context)
            visibleTextRange?.length = lastLine.range.location + lastLine.range.length
            return
        }
        let outOfRangeTextWidth = self.outOfRangeTextWidth >= textRect.width ? 0 : self.outOfRangeTextWidth
        let expectLastLineWidth = textRect.width - outOfRangeTextWidth
        if lastLine.width <= expectLastLineWidth {
            context.textPosition = lineXCorrection(lineOrigin: lastLine.origin, lineWidth: lastLine.width, outOfTextWidth: outOfRangeTextWidth, textRect: textRect, alignment: textAlign)
            visibleTextRange?.length = lastLine.range.location + lastLine.range.length
            DEBUG(true: {
                draw(runs: lastLine.runs, line: lastLine, context: context, debug: debug)
                if outOfRangeTextWidth > 0 {
                    drawOutOfRangeText(
                        at: context.textPosition.x + lastLine.width,
                        context: context,
                        font: lastLine.runs.last?.attributes[NSAttributedString.Key.font] as? UIFont,
                        textColor: lastLine.runs.last?.attributes[NSAttributedString.Key.foregroundColor] as? UIColor,
                        debug: debug)
                }
            }, false: {
                draw(runs: lastLine.runs, line: lastLine, context: context)
                if outOfRangeTextWidth > 0 {
                    drawOutOfRangeText(
                        at: context.textPosition.x + lastLine.width,
                        context: context,
                        font: lastLine.runs.last?.attributes[NSAttributedString.Key.font] as? UIFont,
                        textColor: lastLine.runs.last?.attributes[NSAttributedString.Key.foregroundColor] as? UIColor
                    )
                }
            })
            return
        }
        var (start, end) = lastLine.runs.map({ $0.frame.maxX }).lf_bsearch(expectLastLineWidth, comparable: { (l, r) -> Int in
            Int(l - r)
        })
        let visiableRuns = Array(lastLine.runs.prefix(end))
        let visiableRunWidth = visiableRuns.reduce(0, { (result, run) -> CGFloat in
            result + run.frame.width
        })
        end = min(lastLine.runs.count - 1, end)
        let lastRun = lastLine.runs[end]
        (start, end) = lastRun.glyphPoints.map({ $0.x }).lf_bsearch(expectLastLineWidth, comparable: { (l, r) -> Int in
            Int(l - r)
        })

        // 最后一行内容的宽度，不算outOfRangeText
        var lastLineWidth: CGFloat = visiableRunWidth
        if !lastRun.indices.isEmpty {
            start = min(max(0, start), lastRun.indices.count - 1)
            visibleTextRange?.length = lastRun.indices[start]
            lastLineWidth += lastRun.glyphPoints[start].x - lastRun.glyphPoints[0].x
        }
        lastLine.origin = lineXCorrection(lineOrigin: lastLine.origin, lineWidth: lastLineWidth, outOfTextWidth: outOfRangeTextWidth, textRect: textRect, alignment: textAlign)
        lastLine.frame.size.width = lastLineWidth

        context.saveGState()
        context.textPosition = lastLine.origin

        var font = visiableRuns.last?.attributes[NSAttributedString.Key.font] as? UIFont
        var textColor = visiableRuns.last?.attributes[NSAttributedString.Key.foregroundColor] as? UIColor

        DEBUG(true: {
            draw(runs: visiableRuns, line: lastLine, context: context, debug: debug)
            if start != 0 {
                draw(lastRun: lastRun, line: lastLine, context: context, range: CFRange(location: 0, length: start), debug: debug)
                font = lastRun.attributes[NSAttributedString.Key.font] as? UIFont
                textColor = lastRun.attributes[NSAttributedString.Key.foregroundColor] as? UIColor
            }
            if outOfRangeTextWidth > 0 {
                drawOutOfRangeText(at: context.textPosition.x + lastLineWidth, context: context, font: font, textColor: textColor, debug: debug)
            }
        }, false: {
            draw(runs: visiableRuns, line: lastLine, context: context)
            if start != 0 {
                draw(lastRun: lastRun, line: lastLine, context: context, range: CFRange(location: 0, length: start))
                font = lastRun.attributes[NSAttributedString.Key.font] as? UIFont
                textColor = lastRun.attributes[NSAttributedString.Key.foregroundColor] as? UIColor
            }
            if outOfRangeTextWidth > 0 {
                drawOutOfRangeText(at: context.textPosition.x + lastLineWidth, context: context, font: font, textColor: textColor)
            }
        })

        context.restoreGState()
    }

    /// 绘制入口
    /// - Parameters:
    ///   - runs: 要绘制的 runs
    ///   - line: 绘制的 runs 属于的 line，和 runs 没有强关联关系，仅提供上下文
    private func draw(runs: [LKTextRun], line: LKTextLine, context: CGContext, debug: LKTextRenderDebugOptions? = nil) {
        var runs = drawLine(runs: runs, line: line, context: context)
        runs = drawAt(runs: runs, context: context)
        runs = drawEmoji(runs: runs, context: context)
        runs = drawBackground(runs: runs, context: context)
        runs = drawPoint(runs: runs, context: context)
        runs = drawAttachment(runs: runs, context: context)
        runs = drawGlyphTrasform(runs: runs, context: context)

        for run in runs {
            DEBUG(true: {
                run.draw(context: context, debug: debug?.contains(.drawGlyphRect) == true)
            }, false: {
                run.draw(context: context)
            })
        }
    }

    /// 绘制最后一个不是全部显示的 run，因此在方法中调整了 run 的绘制宽度，其他和正常绘制一致
    private func draw(lastRun: LKTextRun, line: LKTextLine, context: CGContext, range: CFRange, debug: LKTextRenderDebugOptions? = nil) {
        lastRun.resetWidthBy(range: range)
        var runs = drawLine(runs: [lastRun], line: line, context: context)
        runs = drawAt(runs: [lastRun], context: context)
        runs = drawEmoji(runs: [lastRun], context: context)
        runs = drawBackground(runs: [lastRun], context: context)
        runs = drawPoint(runs: [lastRun], context: context)
        runs = drawAttachment(runs: [lastRun], context: context)
        runs = drawGlyphTrasform(runs: [lastRun], context: context)

        if let run = runs.first {
            DEBUG(true: {
                run.draw(
                    context: context,
                    range: range,
                    debug: debug?.contains(.drawGlyphRect) == true
                )
            }, false: {
                run.draw(
                    context: context,
                    range: range,
                    debug: debug?.contains(.drawGlyphRect) == true
                )
            })
        }
    }

    private func drawOutOfRangeText(at x: CGFloat, context: CGContext, font: UIFont?, textColor: UIColor?, debug: LKTextRenderDebugOptions? = nil) {
        guard let layout = self.outOfRangeTextLayout,
              let line = layout.lines.last else {
            outOfRangeTextRect = nil
            return
        }
        let originContextX = context.textPosition.x
        context.textPosition.x = x
        line.origin = context.textPosition
        outOfRangeTextRect = line.frame
        draw(runs: line.runs, line: line, context: context, debug: debug)
        context.textPosition.x = originContextX

        DEBUG(true: {
            if debug?.contains(.drawOutOfRangeTextRect) == true {
                let path = UIBezierPath(rect: self.outOfRangeTextRect!)
                context.addPath(path.cgPath)
                context.setStrokeColor(UIColor.red.cgColor)
                context.strokePath()
            }
        })
    }

    /// 返回是否点击在用户自定义的超出省略文本上
    ///
    /// - Parameter point: coretext坐标系下的point
    /// - Returns: Bool
    public func isPointAtOutOfRangeText(_ point: CGPoint) -> Bool {
        guard let outOfRangeTextRect = self.outOfRangeTextRect else {
            return false
        }

        return fuzzyTextRect(outOfRangeTextRect).contains(point)
    }

    // point计算规则为core text坐标系
    /// 返回一个点所在的Index
    ///
    /// - Parameter point: CGPoint,相对rect坐标系的点，使用时需转换
    /// - Returns: CFIndex, 如果找不到返回kCFNotFound
    public func pointAt(_ point: CGPoint) -> PointAtInTextIndex {
        if self.lines.isEmpty {
            return .init(nearist: kCFNotFound, other: kCFNotFound)
        }
        let lineMidYs = self.lines.map({ $0.frame.midY })
        let (topLineIdx, bottomLineIdx) = nearlyIndexAt(lineMidYs, value: point.y)
        if topLineIdx == self.lines.count - 1 {
            let idx = pointAtLastLine(point)
            return .init(nearist: idx, other: idx)
        }
        // topLineIdx <= 0 or found defined line index.
        if bottomLineIdx == 0 || topLineIdx == bottomLineIdx {
            let idx = LKTextLineGetStringIndexForPosition(lines[bottomLineIdx], point, fuzzyTextRect)
            return .init(nearist: idx, other: idx)
        }

        let topFoundIdx = LKTextLineGetStringIndexForPosition(lines[topLineIdx], point, fuzzyTextRect)
        if topFoundIdx == kCFNotFound {
            let idx = LKTextLineGetStringIndexForPosition(lines[bottomLineIdx], point, fuzzyTextRect)
            return .init(nearist: idx, other: kCFNotFound)
        }
        let bottomFoundIdx = LKTextLineGetStringIndexForPosition(lines[bottomLineIdx], point, fuzzyTextRect)
        if bottomFoundIdx == kCFNotFound {
            return .init(nearist: topFoundIdx, other: kCFNotFound)
        }
        if point.y > lineMidYs[topLineIdx] / 2 + lineMidYs[bottomLineIdx] / 2 {
            return .init(nearist: bottomFoundIdx, other: kCFNotFound)
        }
        return .init(nearist: topFoundIdx, other: kCFNotFound)
    }

    private func fuzzyTextRect(_ textRect: CGRect) -> CGRect {
        if isFuzzyPointAt {
            let spacingBetween: CGFloat = lineSpacing
            let out = textRect
                .inset(by: UIEdgeInsets(top: -spacingBetween, left: -spacingBetween, bottom: -spacingBetween, right: -spacingBetween))
                .inset(by: fuzzyEdgeInsets)
            return out
        }
        return textRect
    }

    // point计算规则为core text坐标系
    // 最后一行需要单独计算
    func pointAtLastLine(_ point: CGPoint) -> CFIndex {
        guard let lastLine = self.lastLine, !self.lines.isEmpty else {
            return kCFNotFound
        }

        if let outOfRangeTextRect = self.outOfRangeTextRect,
           fuzzyTextRect(outOfRangeTextRect).contains(point) == true {
            return kCFNotFound
        }

        return LKTextLineGetStringIndexForPosition(lastLine, point, fuzzyTextRect)
    }

    func lineXCorrection(lineOrigin: CGPoint, lineWidth: CGFloat, outOfTextWidth: CGFloat = 0, textRect: CGRect, alignment: NSTextAlignment) -> CGPoint {
        var origin = lineOrigin
        switch alignment {
        case .center:
            origin.x = textRect.minX + (textRect.width - lineWidth - outOfTextWidth) / 2
        case .left, .natural, .justified:
            origin.x = textRect.minX
        case .right:
            origin.x = textRect.minX + textRect.width - lineWidth - outOfTextWidth
        @unknown default:
            break
        }
        return origin
    }
}

extension LKTextRenderEngineImpl: LKTextDrawAt,
    LKTextDrawBackground,
    LKTextDrawPoint,
    LKTextDrawAttachment,
    LKTextDrawEmoji,
    LKTextDrawGlyphTransform,
    LKTextDrawLine {
    var fontSize: CGFloat {
        return font.pointSize
    }
}
