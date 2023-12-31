//
//  LKTextLine.swift
//  LarkUIKit
//
//  Created by 齐鸿烨 on 2017/8/28.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

public typealias LKLineDetail = (width: CGFloat, ascent: CGFloat, descent: CGFloat, leading: CGFloat)

public final class LKTextLine {
    public var width: CGFloat = 0.0
    public var ascent: CGFloat = 0.0
    public var descent: CGFloat = 0.0
    public var leading: CGFloat = 0.0

    // core text坐标系下
    /*
     *         ........ \
     *         .../|...  } ascent
     * (origin)../_|... /
     *         ./..|... } descent
     *         ........ } leading
     */
    // core text坐标系下
    public var origin: CGPoint {
        didSet {
            if origin == oldValue {
                return
            }
            self.frame = LKTextLine.getLineRect(origin: origin, lineDetail: (width, ascent, descent, leading))
        }
    }

    // core text坐标系下
    public var frame: CGRect = .zero

    public private(set) var runs: [LKTextRun] = []

    public var line: CTLine {
        didSet {
            self.runs = self.getRuns(line: line)
            self.doubleCheckAscentDescentLeading()
        }
    }

    // 对应string的range
    public var range: CFRange

    public init(line: CTLine) {
        self.line = line
        (self.width, self.ascent, self.descent, self.leading) = LKTextLine.getLineDetail(line: self.line)
        self.range = CTLineGetStringRange(line)
        self.origin = .zero
        self.runs = self.getRuns(line: line)
        self.doubleCheckAscentDescentLeading()
    }

    private func getRuns(line: CTLine) -> [LKTextRun] {
        let ctruns = CTLineGetGlyphRuns(line) as? [CTRun] ?? []

        return ctruns.map({ LKTextRun(ctrun: $0) })
    }

    /// @see LKLabelTests.testFirstLineAttachment
    private func doubleCheckAscentDescentLeading() {
        for run in self.runs {
            if run.ascent > self.ascent {
                self.ascent = run.ascent
            }

            if run.descent > self.descent {
                self.descent = run.descent
            }

            if run.leading > self.leading {
                self.leading = run.leading
            }
        }
    }
}

extension LKTextLine {
    public static func getLineDetail(line: CTLine) -> LKLineDetail {
        var ascent = CGFloat(), descent = CGFloat(), leading = CGFloat()
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))

        if leading < 0 {
            leading = 0
        }

        return (
            width: width,
            ascent: ascent,
            descent: descent,
            leading: leading
        )
    }

    static func getLineRect(origin: CGPoint, lineDetail: LKLineDetail) -> CGRect {
        let height = lineDetail.ascent + lineDetail.descent + lineDetail.leading

        return CGRect(x: origin.x, y: origin.y - lineDetail.descent - lineDetail.leading, width: lineDetail.width, height: height)
    }
}
