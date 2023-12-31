//
//  LKTextDrawLine.swift
//  RichLabel
//
//  Created by lixiaorui on 2019/10/25.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignTheme

// used for custom draw underline or strikethrough
public struct LKLineStyle {
    public enum Style {
        case dash(width: CGFloat, space: CGFloat)
        case line
    }

    public enum Position {
        case underLine
        case strikeThrough
        case underLineAndStrikeThrough
    }

    public let width: CGFloat
    public let color: UIColor
    public let position: Position
    public let style: Style
    // 为了解决中文下缘线贴文字过近的问题，将下划线划在linespacing上，故下移1.5pt，UI确认视觉效果可以 （搬运的 annotation）
    public var underLineOffset: CGFloat = 1.5

    public init(width: CGFloat = 1.0,
                color: UIColor = UIColor.ud.N650,
                position: Position = .underLine,
                style: Style = .dash(width: 2.0, space: 2.0)) {
        self.width = width
        self.color = color
        self.style = style
        self.position = position
    }
}

protocol LKTextDrawLine {
    func drawLine(runs: [LKTextRun], line: LKTextLine, context: CGContext) -> [LKTextRun]
    func _drawLine(run: LKTextRun, line: LKTextLine, context: CGContext, lineStyle: LKLineStyle, runUnderLineY: CGFloat)
}

extension LKTextDrawLine {
    func drawLine(runs: [LKTextRun], line: LKTextLine, context: CGContext) -> [LKTextRun] {
        if runs.isEmpty {
            return []
        }

        // 1 筛选需要划线的CTRuns
        var needDrawLineRunsAndStyles: [(run: LKTextRun, style: LKLineStyle)] = []
        for run in runs {
            if let attributes = run.attributes as? [NSAttributedString.Key: Any],
               let style = attributes[LKLineAttributeName] as? LKLineStyle {
                needDrawLineRunsAndStyles.append((run: run, style: style))
            }
        }
        // 2.1 计算CTLine中下划线的runUnderLineY
        var runUnderLineY: CGFloat = CGFloat(MAXFLOAT)
        let pt = context.textPosition
        for (run, _) in needDrawLineRunsAndStyles {
            let runDescentLine = pt.y - run.descent - run.leading
            runUnderLineY = (runUnderLineY > runDescentLine) ? runDescentLine : runUnderLineY
        }

        // 3 给需要划线的CTRun划线
        for (run, style) in needDrawLineRunsAndStyles {
            _drawLine(
                run: run,
                line: line,
                context: context,
                lineStyle: style,
                runUnderLineY: runUnderLineY - style.underLineOffset
            )
        }

        return runs
    }

    func _drawLine(run: LKTextRun, line: LKTextLine, context: CGContext, lineStyle: LKLineStyle, runUnderLineY: CGFloat) {
        let width = lineStyle.width == 0 ? 1.0 : lineStyle.width
        let pt = context.textPosition

        // start draw line
        context.saveGState()
        context.beginPath()
        context.setLineWidth(width)
        context.setStrokeColor(lineStyle.color.cgColor)
        switch lineStyle.style {
        case let .dash(dash, space):
            let width = dash == 0 ? 2.0 : dash
            let spacing = space == 0 ? 2.0 : space
            context.setLineDash(phase: 0, lengths: [width, spacing])
        default:
            break
        }

        func addLine(lineY: CGFloat) {
            context.move(to: CGPoint(x: pt.x + run.origin.x, y: lineY))
            context.addLine(to: CGPoint(x: pt.x + run.origin.x + run.width, y: lineY))
        }

        switch lineStyle.position {
        case .underLine:
            addLine(lineY: runUnderLineY + width)
        case .strikeThrough:
            addLine(lineY: runUnderLineY + line.frame.height * 0.5)
        case .underLineAndStrikeThrough:
            addLine(lineY: runUnderLineY + width)
            addLine(lineY: runUnderLineY + line.frame.height * 0.5)
        }
        context.strokePath()
        context.restoreGState()
    }

    private func systemLineWith(for style: Int) -> CGFloat? {
        // the following config is from origin LKTextDrawStrikeThrough
        let lineStyle = NSUnderlineStyle(rawValue: style)
        if lineStyle.contains(.single) {
            return 1.0
        }
        if lineStyle.contains(.thick) {
            return 2.0
        }
        return nil
    }
}
