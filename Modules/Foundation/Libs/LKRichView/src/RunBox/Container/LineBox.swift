//
//  LineBox.swift
//  LKRichView
//
//  Created by qihongye on 2019/10/15.
//

import UIKit
import Foundation

final class LineBox {

    var debugOptions: ConfigOptions?

    var style: RenderStyleOM
    var runBoxs: [RunBox] = []
    /// These values will set after reflow() called.
    private(set) var ascent: CGFloat = 0
    private(set) var descent: CGFloat = 0
    private(set) var leading: CGFloat = 0

    // MARK: - size

    private(set) var size: CGSize = .zero

    /// 自身baseline的位置
    private(set) var baselineOrigin: CGPoint = .zero

    var writingMode: WritingMode {
        return style.writingMode
    }

    var crossAxisAlign: VerticalAlign {
        return style.verticalAlign
    }

    /// 相对全局的原点位置
    var origin: CGPoint = .zero {
        didSet {
            reflow()
        }
    }

    var globalRect: CGRect {
        return .init(origin: origin, size: size)
    }

    private(set) var mainAxisWidth: CGFloat {
        get {
            size.mainAxisWidth(writingMode: writingMode)
        }
        set {
            size.setMainAxisWidth(writingMode: writingMode, newValue)
        }
    }

    private(set) var crossAxisWidth: CGFloat {
        get {
            size.crossAxisWidth(writingMode: writingMode)
        }
        set {
            size.setCrossAxisWidth(writingMode: writingMode, newValue)
        }
    }

    private var cacheLKTextOverflow: LKTextOverflow = .none
    private var textOverflowToken: NSAttributedString?

    init(style: RenderStyleOM, debugOptions: ConfigOptions? = nil) {
        self.style = style
        self.debugOptions = debugOptions
    }

    func draw(_ paintInfo: PaintInfo) {
        let context = paintInfo.graphicsContext
        let debug = paintInfo.debugOptions?.debug ?? false
        runBoxs.forEach { box in
            #if DEBUG
            if debug {
                drawDebugLines(context, box.fullLineGlobalRect)
            }
            #endif
            debugOptions?.log?.debug(id: nil, message: "RunBox ascent: \(box.ascent) descent: \(box.descent) leading: \(box.leading)", params: nil)
            box.draw(paintInfo)
        }
    }

    func append(runBox: RunBox) {
        runBox.debugOptions = debugOptions
        runBox.ownerLineBox = self
        runBoxs.append(runBox)
    }

    /// remainedMainAxisWidth：当前LineBox剩余的宽度
    func truncatedIfNeeded(context: LayoutContext?, remainedMainAxisWidth: inout CGFloat) {
        buildLKTextOverflowTokenIfNeeded(context: context)
        guard let token = self.textOverflowToken, let lastRunBox = runBoxs.last else { return }

        // 构造Token对应的TextRunBox并进行布局计算，renderContextLocation可以随便给一个，只要比目前已算出来的大即可
        let typeSetter = TextTypeSetter(TextFrameSetter(token))
        let tokenRunBox = TextRunBox(
            style: style,
            typeSetter: typeSetter,
            lineRange: CFRange(location: 0, length: token.length),
            renderContextLocation: lastRunBox.renderContextLocation + lastRunBox.renderContextLength
        )
        tokenRunBox.layoutIfNeeded(context: nil)

        // 如果当前LineBox剩余的宽度不能展示下token，则需要对最后一个RunBox进行裁剪
        while let lastRunBox = runBoxs.last, remainedMainAxisWidth < tokenRunBox.mainAxisWidth {
            let oldRemainedMainAxisWidth = remainedMainAxisWidth
            lastRunBox.truncate(with: tokenRunBox, remainedMainAxisWidth: &remainedMainAxisWidth)
            // 如果两次大小没有变化，则应该是遇到了异常情况，需要退出while循环
            if remainedMainAxisWidth <= oldRemainedMainAxisWidth { break }
        }
        // 裁剪完后，加上token
        self.append(runBox: tokenRunBox)
        // 修正self.contentSize
        self.reflow()
    }

    private func buildLKTextOverflowTokenIfNeeded(context: LayoutContext?) {
        // 如果是因为lineCamp的限制导致后续内容不展示，此时"省略号"以lineCamp设置的内容为准
        if let lineCamp = context?.lineCamp,
           lineCamp.maxLine == 1,
           textOverflowToken?.string != lineCamp.blockTextOverflow {
            self.textOverflowToken = RenderText.createAttributedStringWith(
                text: lineCamp.blockTextOverflow, renderStyle: style
            )
            return
        }

        // 检测cache，避免重复计算
        if cacheLKTextOverflow == style.textOverflow { return }
        cacheLKTextOverflow = style.textOverflow

        // 设置了textOverflow表示最多只展示一行，此时"省略号"以textOverflow设置的内容为准
        var tokenStr: String
        switch cacheLKTextOverflow {
        case .none:
            return
        case .noWrapEllipsis:
            // "\u{2026}" == "..."
            tokenStr = "\u{2026}"
        case .noWrapCustom(let token):
            tokenStr = token
        }
        self.textOverflowToken = RenderText.createAttributedStringWith(text: tokenStr, renderStyle: style)
    }

    func reflow() {
        switch writingMode {
        case .horizontalTB:
            reflowHorizon()
        case .verticalLR, .verticalRL:
            reflowVertical()
        }
    }

    private func reflowHorizon() {
        let info = calculateLineInfoHorizon(runBoxs: runBoxs)
        mainAxisWidth = info.mainAxisWidth
        crossAxisWidth = info.crossAxisWidth
        baselineOrigin.y = info.baselineBottom
        ascent = info.ascent
        descent = info.descent
        leading = info.leading

        var origin = self.baselineOrigin
        runBoxs.forEach { box in
            // 如果一个 linebox 中有两段 text，coretext 可能会计算出不同的 ascent descent leading
            // 这样就会导致同一行的下划线会错开，这里统一同一行内所有 TextRunBox 画下划线的 offset
            if let textBox = box as? TextRunBox {
                textBox.underlineOffset = info.wholeLineTextInfos.descent
            }

            switch box.crossAxisAlign {
            case .baseline:
                box.baselineOrigin = origin
            case .top:
                box.origin = CGPoint(x: origin.x, y: crossAxisWidth - box.crossAxisWidth)
            case .bottom:
                box.origin = CGPoint(x: origin.x, y: 0)
            case .middle:
                box.origin = CGPoint(x: origin.x, y: (crossAxisWidth - box.crossAxisWidth) / 2)
            }

            switch writingMode {
            case .horizontalTB:
                origin.x += box.mainAxisWidth
            case .verticalLR, .verticalRL:
                origin.y += box.mainAxisWidth
            }
        }
    }

    private func reflowVertical() {
        assertionFailure("Coming soon.")
    }
}

func calculateLineInfoHorizon(runBoxs: [RunBox]) -> LineLayoutInfo {
    var (topIndices, baselineIndices, middleIndices, bottomIndices) = (
        [Int](), [Int](), [Int](), [Int]()
    )
    var mainAxisWidth = CGFloat(0)
    var textInfos: WholeLineTextInfos = (.zero, .zero, .zero)
    runBoxs.enumerated().forEach { (index, box) in
        if let textBox = box as? TextRunBox {
            textInfos.ascent = max(textInfos.ascent, textBox.ascent)
            textInfos.descent = max(textInfos.descent, textBox.descent)
            textInfos.leading = max(textInfos.leading, textBox.leading)
        }

        mainAxisWidth += box.mainAxisWidth
        switch box.crossAxisAlign {
        case .top:
            topIndices.append(index)
        case .middle:
            middleIndices.append(index)
        case .baseline:
            baselineIndices.append(index)
        case .bottom:
            bottomIndices.append(index)
        }
    }

    // top = ascent + edges.top
    // bottom = descent + leading + edges.bottom
    var (maxAscent, maxDescent, maxDescentLeading, maxTop, maxBottom) = (
        CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))

    baselineIndices.forEach {
        let box = runBoxs[$0]
        maxAscent = max(maxAscent, box.ascent)
        maxDescent = max(maxDescent, box.descent)
        maxDescentLeading = max(maxDescentLeading, box.descent + box.leading)
        maxTop = max(maxTop, box.ascent + box.edges.top)
        maxBottom = max(maxBottom, box.descent + box.leading + box.edges.bottom)
    }
    topIndices.forEach {
        let box = runBoxs[$0]
        let descentLeading = box.contentCrossAxisWidth - maxAscent
        maxDescentLeading = max(maxDescentLeading, descentLeading)
        maxBottom = max(maxBottom, descentLeading + box.edges.bottom)
    }
    bottomIndices.forEach {
        let box = runBoxs[$0]
        let ascent = box.contentCrossAxisWidth - maxDescentLeading
        maxAscent = max(maxAscent, ascent)
        maxTop = max(maxTop, ascent + box.edges.top)
    }
    middleIndices.forEach {
        let box = runBoxs[$0]
        let ascentOrDescentLeading = box.contentCrossAxisWidth / 2
        maxAscent = max(maxAscent, ascentOrDescentLeading)
        maxDescentLeading = max(maxDescentLeading, ascentOrDescentLeading)
        maxTop = max(maxTop, ascentOrDescentLeading + box.edges.top)
        maxBottom = max(maxBottom, ascentOrDescentLeading + box.edges.bottom)
    }

    let leading = maxDescentLeading - maxDescent
    let top = maxTop - maxAscent
    let bottom = maxBottom - maxDescentLeading
    assert(leading >= 0 && top >= 0 && bottom >= 0)
    return .init(
        .horizontalTB,
        mainAxisWidth: mainAxisWidth,
        ascent: maxAscent,
        descent: maxDescent,
        leading: leading,
        edges: .init(top: top, left: .zero, bottom: bottom, right: .zero),
        wholeLineTextInfos: textInfos
    )
}

struct LineLayoutInfo {
    var ascent: CGFloat
    var descent: CGFloat
    var leading: CGFloat
    var mainAxisWidth: CGFloat
    /// padding + border
    var edges: UIEdgeInsets

    var wholeLineTextInfos: WholeLineTextInfos

    var baselineTop: CGFloat {
        switch writingMode {
        case .horizontalTB:
            return ascent + edges.top
        case .verticalLR, .verticalRL:
            return ascent
        }
    }
    var baselineBottom: CGFloat {
        switch writingMode {
        case .horizontalTB:
            return descent + leading + edges.bottom
        case .verticalLR, .verticalRL:
            return descent
        }
    }
    var crossAxisWidth: CGFloat {
        baselineTop + baselineBottom
    }

    private let writingMode: WritingMode

    init(_ writngMode: WritingMode = .horizontalTB,
         mainAxisWidth: CGFloat = 0,
         ascent: CGFloat = 0,
         descent: CGFloat = 0,
         leading: CGFloat = 0,
         edges: UIEdgeInsets = .zero,
         wholeLineTextInfos: WholeLineTextInfos = (.zero, .zero, .zero)) {
        self.writingMode = writngMode
        self.mainAxisWidth = mainAxisWidth
        self.ascent = ascent
        self.descent = descent
        self.leading = leading
        self.edges = edges
        self.wholeLineTextInfos = wholeLineTextInfos
    }
}
