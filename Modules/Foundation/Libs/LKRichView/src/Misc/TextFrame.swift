//
//  TextFrame.swift
//  LKRichView
//
//  Created by qihongye on 2019/9/4.
//

import Foundation
import CoreText
import UIKit

final class TextFrameSetter {
    let ctFrameSetter: CTFramesetter
    /// TextRunBox-split需要使用到原始内容，这里需要进行存储
    private(set) var attributedString: NSAttributedString?

    init(_ attributedString: NSAttributedString, _ saveAttributedString: Bool = false) {
        ctFrameSetter = CTFramesetterCreateWithAttributedString(attributedString)
        if saveAttributedString { self.attributedString = attributedString }
    }

    func getLine() -> TextLine? {
        let ctFrame = CTFramesetterCreateFrame(
            ctFrameSetter,
            CFRange(location: 0, length: 0),
            CGPath(rect: CGRect(origin: .zero, size: MAX_SIZE), transform: nil),
            nil
        )
        let ctLines = CTFrameGetLines(ctFrame)
        let lineCount = CFArrayGetCount(ctLines)
        if lineCount > 0 {
            return TextLine(unsafeBitCast(CFArrayGetValueAtIndex(ctLines, 0), to: CTLine.self))
        }
        return nil
    }

    func getLines(length: Int) -> [TextLine] {
        let ctFrame = CTFramesetterCreateFrame(
            ctFrameSetter,
            CFRange(location: 0, length: length),
            CGPath(rect: CGRect(origin: .zero, size: MAX_SIZE), transform: nil),
            nil
        )
        let ctLines = CTFrameGetLines(ctFrame)
        let lineCount = CFArrayGetCount(ctLines)
        var lines = [TextLine]()
        for i in 0..<lineCount {
            lines.append(TextLine(unsafeBitCast(CFArrayGetValueAtIndex(ctLines, i), to: CTLine.self)))
        }
        return lines
    }
}

final class TextTypeSetter {
    let ctTypeSetter: CTTypesetter
    private(set) var attributedString: NSAttributedString?

    init(_ frameSetter: TextFrameSetter) {
        ctTypeSetter = CTFramesetterGetTypesetter(frameSetter.ctFrameSetter)
        attributedString = frameSetter.attributedString
    }

    /// shouldCluster：为true表示byChar，为false表示byWord
    func getLineRange(startIndex: CFIndex, width: Double, shouldCluster: Bool) -> CFRange {
        let length: CFIndex
        if shouldCluster {
            length = CTTypesetterSuggestClusterBreak(
                ctTypeSetter,
                startIndex,
                width
            )
        } else {
            length = CTTypesetterSuggestLineBreak(
                ctTypeSetter,
                startIndex,
                width
            )
        }

        return CFRange(location: startIndex, length: length)
    }

    func getLine(range: CFRange) -> TextLine {
        let ctLine = CTTypesetterCreateLine(ctTypeSetter, range)
        return TextLine(ctLine, range: range, attributedString: attributedString)
    }
}

final class TextLine {
    private let line: CTLine
    /// 如果字体是斜体，width不会包含斜体的偏移
    private(set) var width: CGFloat = 0
    private(set) var ascent: CGFloat = 0
    private(set) var descent: CGFloat = 0
    private(set) var leading: CGFloat = 0
    private(set) var range: CFRange

    private(set) var runs: [TextRun] = []
    private(set) var attributedString: NSAttributedString?

    var origin: CGPoint = .zero
    private(set) var size: CGSize = .zero

    var rect: CGRect {
        return CGRect(origin: origin, size: size)
    }

    init(_ line: CTLine, range: CFRange? = nil) {
        self.line = line
        self.range = range ?? CTLineGetStringRange(line)
        // CTLine自带了ascent、ascent、leading、width信息，直接获取即可
        width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
        size = CGSize(width: width, height: ascent + descent + leading)
        runs = getRuns(line: line)
    }

    convenience init(_ line: CTLine, range: CFRange? = nil, attributedString: NSAttributedString?) {
        self.init(line, range: range)
        self.attributedString = attributedString
    }

    func adjustByFont(_ font: UIFont) {
        descent = max(-font.descender, descent)
        ascent = max(font.ascender, ascent)
        leading = max(-font.leading, leading)
        size.height = ascent + descent + leading
    }

    func draw(_ context: CGContext, _ debug: Bool) {
        CTLineDraw(line, context)
    }

    func getTruncatedLine(width: Double, truncationToken: CTLine?) -> TextLine? {
        guard let ctline = CTLineCreateTruncatedLine(line, width, .end, truncationToken) else {
            return nil
        }
        return TextLine(ctline, range: range, attributedString: attributedString)
    }

    private func getRuns(line: CTLine) -> [TextRun] {
        let ctruns = CTLineGetGlyphRuns(line) as? [CTRun] ?? []
        return ctruns.map({ TextRun(ctrun: $0) })
    }

    var debugDescription: String? {
        return attributedString?.attributedSubstring(from: NSRange(location: range.location, length: range.length)).string
    }
}

let CFRANGE_ZERO = CFRangeMake(0, 0)

final class TextRun {
    public static func createCTRunDelegate<T>(
        _ obj: T,
        dealloc: @escaping CoreText.CTRunDelegateDeallocateCallback,
        getAscent: @escaping CoreText.CTRunDelegateGetAscentCallback,
        getDescent: @escaping CoreText.CTRunDelegateGetAscentCallback,
        getWidth: @escaping CoreText.CTRunDelegateGetWidthCallback
    ) -> CTRunDelegate {
        var delegateCallbacks = CTRunDelegateCallbacks(version: kCTRunDelegateCurrentVersion,
                                                       dealloc: dealloc,
                                                       getAscent: getAscent,
                                                       getDescent: getDescent,
                                                       getWidth: getWidth)

        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        pointer.initialize(to: obj)

        return CTRunDelegateCreate(&delegateCallbacks, pointer)!
    }

    var width: CGFloat = 0.0
    var ascent: CGFloat = 0.0
    var descent: CGFloat = 0.0
    var leading: CGFloat = 0.0

    // core text坐标系下, origin相对CTLine坐标系，因此origin.y一般与实际文本位置无关
    /*
     *         ........ \
     *         .../|...  } ascent
     * (origin)../_|... /
     *         ./..|... } descent
     *         ........
     } leading
     */
    var origin: CGPoint {
        let glyphPoints = self.glyphPoints
        return glyphPoints.first ?? .zero
    }

    public var run: CTRun {
        didSet {
            self.attributes = CTRunGetAttributes(self.run)
            self.glyphs = getGlyphs(run: self.run)
            self.glyphPoints = getGlyphPoints(run: self.run)
            self.range = CTRunGetStringRange(self.run)
            self.indices = getGlyphIndices(run: self.run)
        }
    }

    lazy var frame: CGRect = {
        return CGRect(origin: origin, size: CGSize(width: width, height: ascent + descent + leading))
    }()

    public lazy var glyphs: [CGGlyph] = {
        return getGlyphs(run: self.run)
    }()

    public lazy var glyphPoints: [CGPoint] = {
        return getGlyphPoints(run: self.run)
    }()

    public lazy var glyphSizes: [CGSize] = {
        return getGlyphSizes(run: run)
    }()

    public lazy var range: CFRange = {
        return CTRunGetStringRange(self.run)
    }()

    public lazy var indices: [CFIndex] = {
        return getGlyphIndices(run: self.run)
    }()

    private(set) var attributes: NSDictionary

    init(ctrun: CTRun) {
        self.run = ctrun
        self.attributes = CTRunGetAttributes(ctrun)
        self.width = CGFloat(CTRunGetTypographicBounds(ctrun, CFRANGE_ZERO, &self.ascent, &self.descent, &self.leading))
    }

    func draw(context: CGContext, range: CFRange = CFRANGE_ZERO, debug: Bool = false) {
        let trans = CTRunGetTextMatrix(run)
        if !trans.isIdentity {
            context.saveGState()
            context.textMatrix = context.textMatrix.concatenating(trans)
        }
        CTRunDraw(run, context, range)

        if !trans.isIdentity {
            context.restoreGState()
        }
    }

    /// 根据 range 重新计算自己的宽度
    func resetWidthBy(range: CFRange) {
        self.width = CGFloat(CTRunGetTypographicBounds(run, range, &self.ascent, &self.descent, &self.leading))
    }
}

private extension TextRun {
    func getGlyphIndices(run: CTRun) -> [CFIndex] {
        let glyphCount = CTRunGetGlyphCount(self.run)
        if let indicesPtr = CTRunGetStringIndicesPtr(run) {
            return Array(UnsafeBufferPointer(start: indicesPtr, count: glyphCount))
        }
        var indices = [CFIndex](repeating: kCFNotFound, count: glyphCount)
        CTRunGetStringIndices(run, CFRANGE_ZERO, &indices)
        return indices
    }

    func getGlyphs(run: CTRun) -> [CGGlyph] {
        let glyphCount = CTRunGetGlyphCount(self.run)
        if let glyphs = CTRunGetGlyphsPtr(run) {
            return Array(UnsafeBufferPointer(start: glyphs, count: glyphCount))
        }
        var glyphs = [CGGlyph](repeating: CGGlyph(), count: glyphCount)
        CTRunGetGlyphs(run, CFRANGE_ZERO, &glyphs)
        return glyphs
    }

    func getGlyphPoints(run: CTRun) -> [CGPoint] {
        let glyphCount = CTRunGetGlyphCount(self.run)
        if let points = CTRunGetPositionsPtr(run) {
            return Array(UnsafeBufferPointer(start: points, count: glyphCount))
        }
        var points = [CGPoint](repeating: .zero, count: glyphCount)
        CTRunGetPositions(run, CFRANGE_ZERO, &points)
        return points
    }

    func getGlyphSizes(run: CTRun) -> [CGSize] {
        let glyphCount = CTRunGetGlyphCount(self.run)
        if let sizes = CTRunGetAdvancesPtr(run) {
            return Array(UnsafeBufferPointer(start: sizes, count: glyphCount))
        }
        var sizes = [CGSize](repeating: .zero, count: glyphCount)
        CTRunGetAdvances(run, CFRANGE_ZERO, &sizes)
        return sizes
    }
}
