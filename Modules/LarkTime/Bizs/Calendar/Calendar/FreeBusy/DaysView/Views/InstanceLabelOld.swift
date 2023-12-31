//
//  InstanceLabel.swift
//  Calendar
//
//  Created by zhouyuan on 2019/1/8.
//  Copyright © 2019 EE. All rights reserved.
//
import Foundation
import CalendarFoundation
import UIKit

protocol CalendarInstanceLabel: UIView {
    var attributedText: NSAttributedString? { get set }
}

public final class InstanceLabelOld: UIView, CalendarInstanceLabel {
    public var attributedText: NSAttributedString? {
        didSet {
            setNeedsDisplay()
        }
    }

    public init() {
        super.init(frame: .zero)
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let attrString = attributedText else { return }
        // 1
        guard let context = UIGraphicsGetCurrentContext() else { return }
        // 2
        context.textMatrix = .identity
        context.translateBy(x: 0, y: bounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        // 3
        let path = CGMutablePath()
        path.addRect(self.bounds)
        // 4
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrString.length), path, nil)
        // 1.获得CTLine数组
        let lines = CTFrameGetLines(frame) as NSArray
        // 2.获得行数
        let numberOfLines = CFArrayGetCount(lines)
        // 3.获得每一行的origin, CoreText的origin是在字形的baseLine处的, 请参考字形图
        var lineOrigins = [CGPoint](repeating: .zero, count: numberOfLines)
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), &lineOrigins)
        for index in 0..<lines.count {
            let origin = lineOrigins[index]
            // 设置每一行的位置
            context.textPosition = CGPoint(x: origin.x, y: origin.y)
            let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, index), to: CTLine.self)
            let runs = CTLineGetGlyphRuns(line) as Array
            runs.forEach { run in
                let run = unsafeBitCast(run, to: CTRun.self)
                CTRunDraw(run, context, CFRangeMake(0, 0))
                // 获得run的所有样式
                let attributes = CTRunGetAttributes(run) as NSDictionary
                // 判断是run是否含有删除线样式
                if nil != attributes[NSAttributedString.Key.strikethroughStyle] {
                    // 开始画删除线
                    drawStrikethroughStyle(run: run,
                                           attributes: attributes,
                                           context: context)
                }
            }
        }
    }

    func drawStrikethroughStyle(run: CTRun, attributes: NSDictionary, context: CGContext) {
        // 1.获取删除线样式
        let styleRef = attributes[NSAttributedString.Key.strikethroughStyle]
        var style: NSUnderlineStyle = []
        // swiftlint:disable:next force_cast
        CFNumberGetValue((styleRef as! CFNumber), CFNumberType.sInt64Type, &style)
        // 如果定义为none, 就不用画了
        guard style != [] else {
            return
        }
        // 2.获得画线的宽度
        var lineWidth: CGFloat = 1
        if (style.rawValue & NSUnderlineStyle.thick.rawValue) == NSUnderlineStyle.thick.rawValue {
            lineWidth *= 2
        }
        context.setLineWidth(lineWidth)
        // 3.获取画线的起点
        let points = getGlyphPoints(run: run)
        if points.isEmpty { return }
        let firstPosition = points[0]

        // 4.我们要开始画线了
        context.beginPath()
        // 5.获取定义的线的颜色, 默认为黑色
        if let lineColor = attributes[NSAttributedString.Key.strikethroughColor] {
            // swiftlint:disable:next force_cast
            context.setStrokeColor((lineColor as! UIColor).cgColor)
        } else {
            context.setStrokeColor(UIColor.black.cgColor)
        }
        // 6.字体高度, 中间位置为x高度的一半
        let font = attributes[NSAttributedString.Key.font] ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
        var strikeHeight: CGFloat = (font as AnyObject).xHeight / 2.0 + firstPosition.y
        // 多行调整
        let pt = context.textPosition
        strikeHeight += pt.y
        // 画线的宽度
        let typographicWidth = CGFloat(CTRunGetTypographicBounds(run, CFRangeMake(0, 0), nil, nil, nil))
        // 7.开始画线
        context.move(to: CGPoint(x: pt.x + firstPosition.x, y: strikeHeight))
        context.addLine(to: CGPoint(x: pt.x + firstPosition.x + typographicWidth, y: strikeHeight))
        context.strokePath()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func getGlyphPoints(run: CTRun) -> [CGPoint] {
        let glyphCount = CTRunGetGlyphCount(run)
        if let points = CTRunGetPositionsPtr(run) {
            return Array(UnsafeBufferPointer(start: points, count: glyphCount))
        }
        var points = [CGPoint](repeating: .zero, count: glyphCount)
        CTRunGetPositions(run, CFRangeMake(0, 0), &points)
        return points
    }
}
