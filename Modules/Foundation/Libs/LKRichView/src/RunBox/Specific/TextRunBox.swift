//
//  TextRunBox.swift
//  LKRichView
//
//  Created by qihongye on 2019/10/15.
//

import UIKit
import Foundation

typealias WholeLineTextInfos = (ascent: CGFloat, descent: CGFloat, leading: CGFloat)

/// RenderText中生成，一个TextRunBox封装一个TextLine
final class TextRunBox: RunBox {
    private static let spaceString = RenderText.createAttributedStringWith(text: " ", renderStyle: RenderStyleOM(LKRenderRichStyle()))
    private static let spaceLine = TextLine(CTLineCreateWithAttributedString(TextRunBox.spaceString))

    weak var ownerLineBox: LineBox?
    weak var ownerRenderObject: RenderObject?
    var writingMode: WritingMode {
        style.writingMode
    }
    var crossAxisAlign: VerticalAlign {
        style.verticalAlign
    }
    var isSplit: Bool = false

    var isLineBreak: Bool = false

    var debugOptions: ConfigOptions?

    // MARK: - origin

    var origin: CGPoint = .zero {
        didSet {
            ownerRenderObject?.boxOrigin = globalOrigin
        }
    }
    var baselineOrigin: CGPoint {
        get {
            CGPoint(x: origin.x, y: origin.y + descent + leading)
        }
        set {
            origin = CGPoint(x: newValue.x, y: newValue.y - descent - leading)
        }
    }
    var globalOrigin: CGPoint {
        let baseOrigin = ownerLineBox?.origin ?? .zero
        return CGPoint(x: origin.x + baseOrigin.x, y: origin.y + baseOrigin.y)
    }
    var globalBaselineOrigin: CGPoint {
        switch writingMode {
        case .horizontalTB:
            return CGPoint(x: globalOrigin.x, y: globalOrigin.y + descent + leading)
        case .verticalLR, .verticalRL:
            return CGPoint(x: globalOrigin.x + descent + leading, y: globalOrigin.y)
        }
    }

    // MARK: - width

    var mainAxisWidth: CGFloat {
        contentMainAxisWidth
    }
    var contentMainAxisWidth: CGFloat {
        contentSize.mainAxisWidth(writingMode: writingMode)
    }
    var crossAxisWidth: CGFloat {
        contentCrossAxisWidth
    }
    var contentCrossAxisWidth: CGFloat {
        return contentSize.crossAxisWidth(writingMode: writingMode)
    }

    // MARK: - size

    private(set) var ascent: CGFloat = 0
    private(set) var descent: CGFloat = 0
    private(set) var leading: CGFloat = 0
    private(set) var contentSize: CGSize = .zero
    let edges: UIEdgeInsets = .zero
    var size: CGSize {
        if writingMode == .horizontalTB {
            return CGSize(width: mainAxisWidth, height: crossAxisWidth)
        } else {
            return CGSize(width: crossAxisWidth, height: mainAxisWidth)
        }
    }

    var underlineOffset: CGFloat = 0

    // MARK: - context

    var _renderContextLocation: Int
    var renderContextLocation: Int {
        (ownerRenderObject?.renderContextLocation ?? _renderContextLocation) + lineRange.location
    }
    var renderContextLength: Int {
        lineRange.length
    }

    // MARK: - out of RunBox protocol

    private let style: RenderStyleOM
    private let typeSetter: TextTypeSetter
    private var isNoWrap: Bool {
        return style.textOverflow != .none
    }

    private(set) var lineRange: CFRange

    var textLine: TextLine

    init(
        style: RenderStyleOM,
        typeSetter: TextTypeSetter,
        lineRange: CFRange,
        renderContextLocation: Int
    ) {
        self.style = style
        self.typeSetter = typeSetter
        self.lineRange = lineRange
        self._renderContextLocation = renderContextLocation
        self.textLine = typeSetter.getLine(range: lineRange)
    }

    func truncate(with tokenRunBox: TextRunBox, remainedMainAxisWidth: inout CGFloat) {
        guard let ownerLineBox = ownerLineBox else { return }

        // 自身textLine应该被裁减到多少宽度
        let maxWidth = self.mainAxisWidth - fontStyleOffset() - (tokenRunBox.mainAxisWidth - remainedMainAxisWidth)

        // 自身的宽度 + remainedMainAxisWidth要足以展示下token，否则直接清空自身
        if (self.mainAxisWidth + remainedMainAxisWidth) > tokenRunBox.mainAxisWidth,
           // 重新根据最大宽度限制分割自身内容
           maxWidth > 0, let line = self.textLine.getTruncatedLine(width: maxWidth, truncationToken: nil) {
            self.textLine = line
            let oldMainAxisWidth = self.mainAxisWidth
            // 修正self.contentSize
            self.layout(line: self.textLine)
            remainedMainAxisWidth += (oldMainAxisWidth - self.mainAxisWidth)
        } else {
            // 如果裁剪出错，此时直接清空自身
            remainedMainAxisWidth += self.mainAxisWidth
            ownerLineBox.runBoxs.removeLast()
        }
    }

    func layoutIfNeeded(context: LayoutContext?) {
        if crossAxisWidth == 0 || mainAxisWidth == 0 {
            layout(context: context)
        }
    }

    func layout(context: LayoutContext?) {
        if calcMaxLine(style: style, context: context) == 0 {
            return
        }
        layout(line: textLine)
    }

    func layout(line: TextLine) {
        line.adjustByFont(style.font)
        descent = line.descent
        ascent = line.ascent
        leading = line.leading
        contentSize = CGSize(width: line.width + fontStyleOffset(), height: line.size.height)
    }

    func draw(_ paintInfo: PaintInfo) {
        let context = paintInfo.graphicsContext
        let debug = paintInfo.debugOptions?.debug ?? false
        context.textPosition = self.globalBaselineOrigin
        textLine.draw(context, debug)
        drawTextDecoration(context)
    }

    func split(mainAxisWidth: CGFloat, first: Bool, context: LayoutContext?) -> RunBoxSplitResult {
        // 如果自身的宽度比较小，不需要做裁剪，完全可以放下
        guard self.mainAxisWidth > mainAxisWidth else {
            return .breakLine
        }

        // 如果是斜体，则首个字符会往左多占用距离，需要减掉
        let offset = self.fontStyleOffset()
        let mainAxisWidth = mainAxisWidth - offset
        // 获取指定宽度下，能展示的range范围
        var range = CFRange(location: 0, length: 0); var line = self.textLine

        /// coretext 算出来的 line.width 有可能比给的宽度大，在正常情况下，这些小的误差可以被接受
        /// 但有一种场景，即当前行剩下的空间很小，远远不足以放下一个汉字，例如字的宽度是 17，剩下的宽度是 5
        /// 这时候 CoreText 仍旧会把这个字放在这个不够的空间，为了在不影响正常误差的前提下，仅避免这种场景
        /// 引入以下逻辑。（误差在 1 以内可以接受）。如果return true，表示无法分割，需要把self单独放到下一行继续处理
        let currTextSplitFailureForByChar: () -> Bool = { [weak self] in
            guard let `self` = self else { return false }
            if let renderText = self.ownerRenderObject as? RenderText {
                // range是struct CFRange类型，测试出来能获取到修改后的值，属于引用捕获
                let slice = Array(renderText.utf16Array[range.location ..< range.location + range.length])
                // 这里 trim 了空格，是为了避免 SuggestLineBreak 虽然返回了一个字，但这个字后面带了一个空格的情况
                // 这样的情况会导致下面的 count == 1 无法拦截，从而导致这个兜底逻辑失效；加 < 1是处理全是空格的情况
                var subStr = String(utf16CodeUnits: slice, count: slice.count)
                subStr = subStr.trimmingCharacters(in: .whitespacesAndNewlines)
                if subStr.count <= 1, line.width > mainAxisWidth + 1 {
                    return true
                }
            }
            return false
        }

        // byChar，直接使用线上逻辑即可
        if isNoWrap {
            range = typeSetter.getLineRange(startIndex: lineRange.location, width: Double(mainAxisWidth), shouldCluster: true)
            line = typeSetter.getLine(range: range)
            // 如果是非首行
            if currTextSplitFailureForByChar() {
                return .failure(lhs: self, rhs: nil)
            }
        }
        // byWord && 行首，则直接使用线上逻辑
        else if first {
            range = typeSetter.getLineRange(startIndex: lineRange.location, width: Double(mainAxisWidth), shouldCluster: false)
            line = typeSetter.getLine(range: range)
            // coretext 算出来的 line.width 会比给的宽度大很多，这时候我们需要进行二分，查找一个最长的匹配结果
            if line.width > mainAxisWidth + 1 {
                // 二分找到了合适的结果，更正之前的计算结果，此修正逻辑结束
                if let result = self.binarySearch(mainAxisWidth: mainAxisWidth) {
                    range = result.0; line = result.1
                } else {
                    // 如果二分都没有找到一个合适的结果，说明当前word无法分割，此时需要使用byChar进行分割
                    range = typeSetter.getLineRange(startIndex: lineRange.location, width: Double(mainAxisWidth), shouldCluster: true)
                    line = typeSetter.getLine(range: range)
                    if currTextSplitFailureForByChar() {
                        return .failure(lhs: self, rhs: nil)
                    }
                }
            }
        }
        // byWord && 非行首 && 开了FG，则需要添加一个空格再进行计算
        else if let originString = typeSetter.attributedString {
            // 添加一个空格进行计算，有内容能放下
            if let result = self.addSpaceSearch(originString: originString, mainAxisWidth: mainAxisWidth) {
                range = result.0; line = result.1
            } else {
                // 添加一个空格进行计算，没有内容能放下
                return .failure(lhs: self, rhs: nil)
            }
            // 如果算出来的宽度还是宽，此时属于异常情况（系统始终保证有内容返回），此时用二分再修正一下CTTypesetterSuggestLineBreak的计算结果
            if line.width > mainAxisWidth + 1 {
                // 二分找到了合适的结果，更正之前的计算结果，此修正逻辑结束
                if let result = self.binarySearch(mainAxisWidth: mainAxisWidth) {
                    range = result.0; line = result.1
                } else {
                    return .failure(lhs: self, rhs: nil)
                }
            }
        }
        // byWord && 非行首 && 没开FG，则使用线上逻辑
        else {
            range = typeSetter.getLineRange(startIndex: lineRange.location, width: Double(mainAxisWidth), shouldCluster: false)
            line = typeSetter.getLine(range: range)
            // 如果算出来的宽度还是宽，此时属于异常情况（系统始终保证有内容返回），直接换行展示即可
            if line.width > mainAxisWidth + 1 {
                return .failure(lhs: self, rhs: nil)
            }
        }

        // 拆分出来的CTLine，构建一个新的RunBox
        let lhsBox = TextRunBox(
            style: style,
            typeSetter: typeSetter,
            lineRange: range,
            renderContextLocation: renderContextLocation
        )
        lhsBox.ownerRenderObject = ownerRenderObject
        lhsBox.layout(line: line)
        lhsBox.isSplit = true

        // 修正自身的属性
        self.lineRange = CFRange(
            location: range.location + range.length,
            length: self.lineRange.length - range.length
        )
        self.textLine = typeSetter.getLine(range: lineRange)
        self._renderContextLocation += range.length
        self.isSplit = true
        self.layout(context: nil)

        // RenderText添加新增分割的RunBox
        ownerRenderObject?.runBox.appendSplitVal(origin: self, lhs: lhsBox, rhs: self)
        return .success(lhs: lhsBox, rhs: self)
    }

    /// 前方加空格计算
    private func addSpaceSearch(originString: NSAttributedString, mainAxisWidth: CGFloat) -> (CFRange, TextLine)? {
        // 获取原始内容
        let originString = originString.attributedSubstring(from: NSRange(location: lineRange.location, length: lineRange.length))
        // 得到真正参与分割的内容：空格 + 原始内容，进行分割运算
        let allString = NSMutableAttributedString(attributedString: TextRunBox.spaceString); allString.append(originString)
        let length = CTTypesetterSuggestLineBreak(CTTypesetterCreateWithAttributedString(allString), 0, Double(mainAxisWidth) + TextRunBox.spaceLine.width)
        // 如果length为1，说明没有内容能放下，加 < 1是处理未包含空格的异常情况
        if length <= TextRunBox.spaceString.length {
            return nil
        }
        // 如果length为所有内容，说明所有内容都能放下
        let range: CFRange; if length == allString.length {
            range = CFRange(location: lineRange.location, length: lineRange.length)
        } else {
            // 不能放下所有内容，长度需要减去空格
            range = CFRange(location: lineRange.location, length: length - TextRunBox.spaceString.length)
        }
        return (range, typeSetter.getLine(range: range))
    }

    /// 二分查找
    private func binarySearch(mainAxisWidth: CGFloat) -> (CFRange, TextLine)? {
        // 存储满足的匹配结果
        var maxMatchRange: CFRange?; var maxMatchLine: TextLine?
        // 进行二分算法
        var leftWidth: Int = 1; var rightWidth: Int = Int(floor(mainAxisWidth))
        // 这里需要写leftWidth <= rightWidth，不能写leftWidth < rightWidth，例子：后则匹配不到下面的5
        // 1 2 3 4 5 6 7           （left = 1，right = 7）
        //       |                 （mid = 4，满足 右移）
        //         5 6 7           （left = 5，right = 7）
        //           |             （mid = 6，不满足 左移）
        //         5               （left = 5，right = 5，写成 < 则不会算5，直接退出）
        while leftWidth <= rightWidth {
            let midWidth = (leftWidth + rightWidth) / 2
            // 判断当前宽度是否满足要求
            let currRange = typeSetter.getLineRange(
                startIndex: lineRange.location,
                width: Double(midWidth),
                shouldCluster: false // 使用byWord
            )
            let currLine = typeSetter.getLine(range: currRange)
            // 当前宽度满足要求，继续往右增加长度
            if currLine.width <= mainAxisWidth + 1 {
                maxMatchRange = currRange
                maxMatchLine = currLine
                // + 1的原因：因为midWidth值已经计算过了，无需再算
                leftWidth = midWidth + 1
            } else {
                // 当前宽度不满足要求，继续往左减少长度；- 1的原因：因为midWidth值已经计算过了，无需再算
                rightWidth = midWidth - 1
            }
        }
        // 是否找到了合适的结果
        if let matchRange = maxMatchRange, let matchLine = maxMatchLine {
            return (matchRange, matchLine)
        }
        return nil
    }

    private func fontStyleOffset() -> CGFloat {
        switch style.fontStyle {
        case .italic:
            return CGFloat(tanf(.pi / 180 * 15)) * style.font.pointSize
        case .normal:
            return .zero
        }
    }

    private func drawTextDecoration(_ context: CGContext) {
        guard let textDirections = style.textDirection else {
            return
        }
        let contextBaselineOrigin = self.globalBaselineOrigin

        if let td = textDirections.lineThrough {
            let origin = CGPoint(
                x: contextBaselineOrigin.x,
                y: contextBaselineOrigin.y - descent - leading + contentSize.height / 2
            )
            switch td.style {
            case .dashed:
                drawTextDecorationDashed(td, origin: origin, context)
            case .solid:
                drawTextDecorationSolid(td, origin: origin, context)
            case .wave:
                drawTextDecorationWave(td, origin: origin, context)
            }
        }

        if let td = textDirections.underline {
            let lineWidth = td.thickness ?? computeUnderLineWidth(style.fontSize)
            let origin = CGPoint(
                x: contextBaselineOrigin.x,
                y: contextBaselineOrigin.y - underlineOffset + lineWidth
            )
            switch td.style {
            case .dashed:
                drawTextDecorationDashed(td, origin: origin, context)
            case .solid:
                drawTextDecorationSolid(td, origin: origin, context)
            case .wave:
                drawTextDecorationWave(td, origin: origin, context)
            }
        }
    }

    @inline(__always)
    private func drawTextDecorationSolid(_ td: TextDecoration, origin: CGPoint, _ context: CGContext) {
        let path = UIBezierPath()
        path.move(to: origin)
        path.addLine(to: CGPoint(x: origin.x + contentSize.width, y: origin.y))
        path.lineWidth = td.thickness ?? computeUnderLineWidth(style.fontSize)
        context.setStrokeColor(td.color?.cgColor ?? style.color.cgColor)
        context.addPath(path.cgPath)
        context.strokePath()
    }

    @inline(__always)
    private func drawTextDecorationDashed(_ td: TextDecoration, origin: CGPoint, _ context: CGContext) {
        let path = UIBezierPath()
        let dashWidth = style.fontSize / 3
        path.move(to: origin)
        path.addLine(to: CGPoint(x: origin.x + contentSize.width, y: origin.y))
        path.lineWidth = td.thickness ?? computeUnderLineWidth(style.fontSize)
        context.setLineDash(phase: 0, lengths: [2 * dashWidth, dashWidth])
        context.setStrokeColor(td.color?.cgColor ?? style.color.cgColor)
        context.addPath(path.cgPath)
        context.strokePath()
    }

    @inline(__always)
    private func drawTextDecorationWave(_ td: TextDecoration, origin: CGPoint, _ context: CGContext) {
        // TODO: @qhy, find a high performance way to draw a wavy line.
        let path = UIBezierPath()
        path.move(to: origin)
        path.addLine(to: CGPoint(x: origin.x + contentSize.width, y: origin.y))
        path.lineWidth = td.thickness ?? computeUnderLineWidth(style.fontSize)
        context.setStrokeColor(td.color?.cgColor ?? style.color.cgColor)
        context.addPath(path.cgPath)
        context.strokePath()
    }
}

@inline(__always)
func computeUnderLineWidth(_ fontSize: CGFloat) -> CGFloat {
    return CGFloat(Int(fontSize / 12))
}
