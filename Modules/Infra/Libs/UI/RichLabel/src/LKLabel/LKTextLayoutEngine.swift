//
//  LKTextLayoutEngine.swift
//  LarkUIKit
//
//  Created by 齐鸿烨 on 2017/8/25.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import CoreText

let CFRANGE_ZERO = CFRangeMake(0, 0)

public protocol LKTextLayoutEngine: AnyObject {
    static var MAX_FLOAT: CGFloat { get set }

    static var MAX_SIZE: CGSize { get set }

    var textSize: CGSize { get }

    var ctframe: CTFrame? { get }

    var ctframeSetter: CTFramesetter? { get }

    var lines: [LKTextLine] { get }

    var visibleRange: CFRange { get }

    var isOutOfRange: Bool { get }

    var attributedText: NSAttributedString? { get set }

    var numberOfLines: Int { get set }

    var preferMaxWidth: CGFloat { get set }

    var defaultFont: UIFont { get set }

    var outOfRangeText: NSAttributedString? { get set }

    var outOfRangeTextWidth: CGFloat { get }

    var outOfRangeTextLayout: LKTextLayoutEngine? { get }

    var lineSpacing: CGFloat { get set }

    @discardableResult
    func layout(size: CGSize) -> CGSize

    func clone() -> LKTextLayoutEngine
}

public final class LKTextLayoutEngineImpl: LKTextLayoutEngine {
    public static var MAX_FLOAT: CGFloat = 100_000
    public static var MAX_SIZE = CGSize(width: MAX_FLOAT, height: MAX_FLOAT)
    private static var SYSTEM_FONT = UIFont.systemFont(ofSize: UIFont.systemFontSize)

    private var sizeCache: [CGFloat: CGSize] = [:]
    private var linesCache: [CGFloat: [LKTextLine]] = [:]

    public private(set) var textSize: CGSize = .zero

    public private(set) var ctframe: CTFrame?

    public private(set) var ctframeSetter: CTFramesetter?

    public private(set) var lines: [LKTextLine] = []

    public private(set) var visibleRange: CFRange = CFRANGE_ZERO

    public private(set) var isOutOfRange: Bool = false

    public private(set) var outOfRangeTextLayout: LKTextLayoutEngine?

    private var _attributedTextLock = pthread_rwlock_t()

    fileprivate var _outOfRangeText: NSAttributedString?
    fileprivate var _needLayoutOutOfRangeText = false
    public var outOfRangeText: NSAttributedString? {
        get {
            pthread_rwlock_rdlock(&_attributedTextLock)
            defer {
                pthread_rwlock_unlock(&_attributedTextLock)
            }
            return _outOfRangeText
        }
        set {
            pthread_rwlock_wrlock(&_attributedTextLock)
            defer {
                pthread_rwlock_unlock(&_attributedTextLock)
            }
            guard let text = newValue else {
                outOfRangeTextWidth = 0
                _outOfRangeText = nil
                _needLayoutOutOfRangeText = false
                return
            }

            if _outOfRangeText != text {
                _needLayoutOutOfRangeText = true
                // Out of range text should not support link parse, so only adapt with text parser.
                let textParser = LKTextParserImpl()
                textParser.defaultFont = self.defaultFont
                textParser.originAttrString = text
                textParser.parse()

                let layout = outOfRangeTextLayout ?? LKTextLayoutEngineImpl()
                layout.attributedText = textParser.renderAttrString
                layout.numberOfLines = 1
                layout.lineSpacing = self.lineSpacing
                outOfRangeTextLayout = layout
            }
            _outOfRangeText = text
        }
    }

    public private(set) var outOfRangeTextWidth: CGFloat = 0

    fileprivate var _attributedText: NSAttributedString?
    public var attributedText: NSAttributedString? {
        get {
            pthread_rwlock_rdlock(&_attributedTextLock)
            defer {
                pthread_rwlock_unlock(&_attributedTextLock)
            }
            return _attributedText
        }
        set {
            guard let attrText = newValue else {
                pthread_rwlock_wrlock(&_attributedTextLock)
                _attributedText = nil
                pthread_rwlock_unlock(&_attributedTextLock)
                self.reset()
                return
            }

            pthread_rwlock_wrlock(&_attributedTextLock)
            if _attributedText == nil || !attrText.isEqual(to: _attributedText!) {
                _attributedText = newValue
                pthread_rwlock_unlock(&_attributedTextLock)
                self.reset()
                self.ctframeSetter = CTFramesetterCreateWithAttributedString(attrText)
                return
            }
            _attributedText = newValue
            pthread_rwlock_unlock(&_attributedTextLock)
        }
    }

    public var numberOfLines: Int = 0

    public var preferMaxWidth: CGFloat = 0

    public var lineSpacing: CGFloat = 0

    public var defaultFont = LKTextLayoutEngineImpl.SYSTEM_FONT

    public init() {
        pthread_rwlock_init(&_attributedTextLock, nil)
    }

    func reset() {
        pthread_rwlock_wrlock(&_attributedTextLock)
        defer {
            pthread_rwlock_unlock(&_attributedTextLock)
        }
        lines = []
        ctframe = nil
        ctframeSetter = nil
        sizeCache = [:]
        linesCache = [:]
        textSize = .zero
    }

    public func layout(size: CGSize) -> CGSize {
        pthread_rwlock_wrlock(&_attributedTextLock)
        defer {
            pthread_rwlock_unlock(&_attributedTextLock)
        }
        guard self.ctframeSetter != nil else { return .zero }
//        if let layoutSize = self.sizeCache[size.width], let layoutLines = self.linesCache[size.width] {
//            self.lines = layoutLines
//            return layoutSize
//        }

        self.lines = []
        // size limit
        var constraints = size
        if self.preferMaxWidth > 0 {
            constraints.width = self.preferMaxWidth
        } else if constraints.width < 0 {
            constraints.width = LKTextLayoutEngineImpl.MAX_FLOAT
        }
        if constraints.height < 0 {
            constraints.height = LKTextLayoutEngineImpl.MAX_FLOAT
        }

        // process
        let path = CGPath(rect: CGRect(x: 0, y: 0, width: constraints.width, height: LKTextLayoutEngineImpl.MAX_FLOAT), transform: nil)
        self.ctframe = CTFramesetterCreateFrame(self.ctframeSetter!, CFRANGE_ZERO, path, nil)
        let ctLines = CTFrameGetLines(self.ctframe!)
        var linesCount = CFArrayGetCount(ctLines)
        let originLinesCount = linesCount
        if linesCount == 0 {
            return .zero
        }

        // lines limit
        if self.numberOfLines != 0 && linesCount > self.numberOfLines {
            linesCount = numberOfLines
        }
        var lineOrigins = [CGPoint](repeating: CGPoint(x: 0, y: 0), count: linesCount)

        var line: CTLine
        var lkline: LKTextLine
        var height: CGFloat = 0
        var nextHeight = height
        var lineIdx = 0

        constraints.width = 0

        // 遍历每一行进行绘制
        while lineIdx < linesCount {
            guard let pointer = CFArrayGetValueAtIndex(ctLines, lineIdx) else {
                lineIdx += 1
                assertionFailure("CTLinePointer is undefined.")
                break
            }
            line = unsafeBitCast(pointer, to: CTLine.self)
            lkline = LKTextLine(line: line)

            lineOrigins[lineIdx].y = -height - lkline.ascent
            nextHeight += lkline.ascent + lkline.descent + lkline.leading

            self.lines.append(lkline)
            lineIdx += 1
            /// NOTES: 由于系统返回的 rect 在精度上会有非常非常小的偏差, 增加0.4(视觉不可见, 0.5时视觉可见)的合法偏差精度.
            if lineIdx > 1 && (nextHeight - constraints.height) > 0.4 {
                _ = self.lines.popLast()
                lineIdx -= 1
                break
            }
            nextHeight += self.lineSpacing
            height = nextHeight
            if constraints.width < lkline.width {
                constraints.width = lkline.width
            }
        }
        // 最后一行后面没有spacing，- 1 是为了适配 解决最后一行没有划线空间的问题，给下划线预留一些空间，导致的上方空间不足问题
        height -= (self.lineSpacing - 1)

        visibleRange = self.getVisibleRange(lines: self.lines)

        if self.isOutOfRange(linesCount: originLinesCount, lines: self.lines) {
            // layout out of range text
            var outOfRangeTextSize = CGSize.zero
            if self._needLayoutOutOfRangeText {
                outOfRangeTextSize = self.outOfRangeTextLayout?.layout(size: Self.MAX_SIZE) ?? .zero
            }
            outOfRangeTextWidth = outOfRangeTextSize.width
            if constraints.width < outOfRangeTextSize.width {
                constraints.width = ceil(outOfRangeTextWidth)
            }
            // last line height < outOfRangeText height
            if let lastline = self.lines.last,
               let outofRangeLine = outOfRangeTextLayout?.lines.first {
                let lineHeight = lastline.ascent + lastline.descent + lastline.leading
                if lineHeight < outOfRangeTextSize.height {
                    lineOrigins[lineIdx - 1].y += lastline.ascent - outofRangeLine.ascent
                    lastline.descent = max(lastline.descent, outofRangeLine.descent)
                    lastline.ascent = max(lastline.ascent, outofRangeLine.ascent)
                    lastline.leading = max(lastline.leading, outofRangeLine.leading)
                    height += outOfRangeTextSize.height - lineHeight
                }
            }
        }

        // @的小圆点某些情况下会挡住一点点
        constraints.width = ceil(constraints.width)
        constraints.height = ceil(height)

        assert(lineOrigins.count >= self.lines.count)

        var transform = CGAffineTransform(translationX: 0, y: 0)
        transform.ty = self.lines[lineIdx - 1].descent - lineOrigins[lineIdx - 1].y + 1 // + 1 的目的是解决最后一行没有划线空间的问题，给下划线预留一些空间
        lineOrigins = lineOrigins.map({ __CGPointApplyAffineTransform($0, transform) })
        for i in 0..<lineIdx {
            self.lines[i].origin = lineOrigins[i]
        }

//        self.sizeCache[size.width] = constraints
//        self.linesCache[size.width] = self.lines

        textSize = constraints

        return constraints
    }

    public func clone() -> LKTextLayoutEngine {
        pthread_rwlock_rdlock(&_attributedTextLock)
        defer {
            pthread_rwlock_unlock(&_attributedTextLock)
        }
        let layout = LKTextLayoutEngineImpl()
        layout.textSize = self.textSize
        layout.ctframe = self.ctframe
        layout.ctframeSetter = self.ctframeSetter
        layout.lines = self.lines
        layout.visibleRange = self.visibleRange
        layout.isOutOfRange = self.isOutOfRange
        layout.numberOfLines = self.numberOfLines
        layout.preferMaxWidth = self.preferMaxWidth
        if let str = self._attributedText {
            layout._attributedText = NSAttributedString(attributedString: str)
        }
        if let str = self._outOfRangeText {
            layout._outOfRangeText = NSAttributedString(attributedString: str)
        }
        layout._needLayoutOutOfRangeText = self._needLayoutOutOfRangeText
        if let outofRangeLayout = self.outOfRangeTextLayout {
            layout.outOfRangeTextLayout = outofRangeLayout
        }
        layout.outOfRangeTextWidth = self.outOfRangeTextWidth
        layout.lineSpacing = self.lineSpacing
        return layout
    }
}

private extension LKTextLayoutEngineImpl {
    func getVisibleRange(lines: [LKTextLine]) -> CFRange {
        if lines.isEmpty {
            return CFRangeMake(0, 0)
        }
        return CFRangeMake(0, lines.last!.range.location + lines.last!.range.length)
    }

    func isOutOfRange(linesCount: Int, lines: [LKTextLine]) -> Bool {
        self.isOutOfRange = linesCount > lines.count
        return self.isOutOfRange
    }
}

public func CreateLKTextLayout(_ attrStr: NSAttributedString, processor: LKTextParser, linkProcessor: LKTextParser) -> LKTextLayoutEngine {
    let layout = LKTextLayoutEngineImpl()
    let mutableAttrStr = NSMutableAttributedString(attributedString: attrStr)
    processor.parse()
    linkProcessor.parse()
    layout.attributedText = mutableAttrStr

    return layout
}
