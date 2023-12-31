//
//  LKTextRun.swift
//  LarkUIKit
//
//  Created by 齐鸿烨 on 2017/8/28.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import CoreText

public final class LKTextRun {
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

    lazy var frame: CGRect = CGRect(origin: origin, size: CGSize(width: width, height: ascent + descent + leading))

    public lazy var glyphs: [CGGlyph] = {
        return getGlyphs(run: self.run)
    }()

    public lazy var glyphPoints: [CGPoint] = {
        return getGlyphPoints(run: self.run)
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

        DEBUG(true: {
            if debug {
                context.saveGState()
                let origin = CGPoint(x: context.textPosition.x + self.origin.x, y: context.textPosition.y - self.descent)
                let path = UIBezierPath(rect: CGRect(origin: origin, size: frame.size))
                path.lineWidth = 1
                path.lineCapStyle = .square
                path.lineJoinStyle = .bevel
                let glyphPoints = self.glyphPoints.suffix(from: range.location).prefix(range.length)
                for glyphPoint in glyphPoints {
                    path.move(to: CGPoint(x: glyphPoint.x + origin.x, y: origin.y))
                    path.addLine(to: CGPoint(x: glyphPoint.x + origin.x, y: origin.y + frame.height))
                }
                UIColor.red.setStroke()
                path.stroke()
                context.restoreGState()
            }
        })

        if !trans.isIdentity {
            context.restoreGState()
        }
    }

    /// 根据 range 重新计算自己的宽度
    func resetWidthBy(range: CFRange) {
        self.width = CGFloat(CTRunGetTypographicBounds(run, range, &self.ascent, &self.descent, &self.leading))
    }
}

private extension LKTextRun {
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
}
