//
//  InlineBlockContainerRunBox.swift
//  LKRichView
//
//  Created by qihongye on 2019/10/22.
//

import UIKit
import Foundation

protocol ContainerRunBox: AnyObject {
    var globalRect: CGRect { get }
    var children: [RunBox] { get }
    func selectionLineInfo() -> [(lineRect: CGRect, subRunBoxs: [RunBox], runBox: RunBox)]
}

class InlineBlockContainerRunBox: RunBox, ContainerRunBox {

    weak var ownerLineBox: LineBox?
    weak var ownerRenderObject: RenderObject?
    var writingMode: WritingMode {
        style.writingMode
    }
    var mainAxisAlign: TextAlign {
        style.textAlign
    }
    var crossAxisAlign: VerticalAlign {
        style.verticalAlign
    }
    var isSplit: Bool = false

    var isLineBreak: Bool {
        get {
            if isInlineBlock {
                return false
            }
            return _isLineBreak
        }
        set {
            _isLineBreak = newValue
        }
    }

    private var _isLineBreak: Bool = false

    var debugOptions: ConfigOptions?

    // MARK: - origin

    var origin: CGPoint = .zero {
        didSet {
            positioningLines()
            ownerRenderObject?.boxOrigin = globalOrigin
        }
    }
    var baselineOrigin: CGPoint {
        get {
            CGPoint(x: origin.x, y: origin.y + descent + leading + edges.bottom)
        }
        set {
            origin = CGPoint(x: newValue.x, y: newValue.y - descent - leading - edges.bottom)
        }
    }
    var globalOrigin: CGPoint {
        let baseOrigin = ownerLineBox?.origin ?? .zero
        return CGPoint(x: origin.x + baseOrigin.x, y: origin.y + baseOrigin.y)
    }
    var globalBaselineOrigin: CGPoint {
        switch writingMode {
        case .horizontalTB:
            return CGPoint(x: globalOrigin.x, y: globalOrigin.y + descent + leading + edges.bottom)
        case .verticalLR, .verticalRL:
            return CGPoint(x: globalOrigin.x + descent + leading + edges.bottom, y: globalOrigin.y)
        }
    }
    var globalContentOrigin: CGPoint {
        CGPoint(x: globalOrigin.x + edges.left, y: globalOrigin.y + edges.bottom)
    }

    // MARK: - width

    var mainAxisWidth: CGFloat {
        style.calculateMainAxisWidth(contentSize: contentSize)
    }
    var crossAxisWidth: CGFloat {
        style.calculateCrossAxisWidth(contentSize: contentSize)
    }
    var contentMainAxisWidth: CGFloat {
        contentSize.mainAxisWidth(writingMode: writingMode)
    }
    var contentCrossAxisWidth: CGFloat {
        contentSize.crossAxisWidth(writingMode: writingMode)
    }

    // MARK: - size

    private(set) var ascent: CGFloat = 0
    private(set) var descent: CGFloat = 0
    private(set) var leading: CGFloat = 0
    private(set) var contentSize: CGSize = .zero
    let edges: UIEdgeInsets
    var size: CGSize {
        if writingMode == .horizontalTB {
            return CGSize(width: mainAxisWidth, height: crossAxisWidth)
        }
        return CGSize(width: crossAxisWidth, height: mainAxisWidth)
    }

    // MARK: - context
    var _renderContextLocation: Int

    var renderContextLength: Int = 1

    // MARK: - out of RunBox protocol

    private let style: RenderStyleOM
    private(set) var lineBoxs: [LineBox] = []
    private let avaliableMainAxisWidth: CGFloat
    private let avaliableCrossAxisWidth: CGFloat
    private var wholeLineCrossWidth: CGFloat = 0
    private var isNoWrap: Bool {
        return style.textOverflow != .none
    }
    /// layout完成后，children的内容将不可信
    var children: [RunBox] = [] {
        didSet {
            _isLineBreak = children.contains { $0.isLineBreak }
        }
    }

    var isInlineBlock = false

    init(style: RenderStyleOM,
         avaliableMainAxisWidth: CGFloat,
         avaliableCrossAxisWidth: CGFloat,
         renderContextLocation: Int,
         children: [RunBox] = []
    ) {
        self.style = style
        self.avaliableMainAxisWidth = avaliableMainAxisWidth
        self.avaliableCrossAxisWidth = avaliableCrossAxisWidth
        self._renderContextLocation = renderContextLocation
        self.children = children
        _isLineBreak = children.contains { $0.isLineBreak }
        let borderEdgeInsets = style.borderEdgeInsets ?? .zero
        edges = UIEdgeInsets(
            top: style.padding.top + borderEdgeInsets.top,
            left: style.padding.left + borderEdgeInsets.left,
            bottom: style.padding.bottom + borderEdgeInsets.bottom,
            right: style.padding.right + borderEdgeInsets.right
        )
    }

    func layoutIfNeeded(context: LayoutContext?) {
        if contentSize.width == 0 || contentSize.height == 0 {
            layout(context: context)
        }
    }

    func layout(context: LayoutContext?) {
        ownerRenderObject?.isContentScroll = false
        // Expired lines count.
        let maxLine = calcMaxLine(style: style, context: context)
        let maxLineNoLimit = maxLine < 0
        if maxLine == 0 {
            reset()
            return
        }

        // 可用的主纵轴宽度，需要 - padding - border
        var (mainAxisWidth, crossAxisWidth): (CGFloat, CGFloat)
        // 下面两个元组是用来辅助修正mainAxisWidth、crossAxisWidth的，可以不用太关心
        let (maxMainAxisWidth, maxCrossAxisWidth): (CGFloat?, CGFloat?)
        let (minMainAxisWidth, minCrossAxisWidth): (CGFloat?, CGFloat?)
        // 假如超出100会展示show more、buffer为20，那么100-120内会把所有内容都展示出来，不展示show more，因为展开20用户可能也无感知
        let maxCrossAxisWidthBuffer = debugOptions?.maxHeightBuffer ?? 0
        switch writingMode {
        case .horizontalTB:
            mainAxisWidth = style.calculateWidthWithEdge(avalidWidth: avaliableMainAxisWidth)
            crossAxisWidth = style.calculateHeightWithEdge(avalidHeight: avaliableCrossAxisWidth)
            maxMainAxisWidth = style.maxWidth(avalidWidth: mainAxisWidth)
            minMainAxisWidth = style.minWidth(avalidWidth: mainAxisWidth)
            maxCrossAxisWidth = style.maxHeight(avalidHeight: crossAxisWidth)
            minCrossAxisWidth = style.minHeight(avalidHeight: crossAxisWidth)
        case .verticalLR, .verticalRL:
            mainAxisWidth = style.calculateHeightWithEdge(avalidHeight: avaliableMainAxisWidth)
            crossAxisWidth = style.calculateWidthWithEdge(avalidWidth: avaliableCrossAxisWidth)
            maxMainAxisWidth = style.maxHeight(avalidHeight: mainAxisWidth)
            minMainAxisWidth = style.minHeight(avalidHeight: mainAxisWidth)
            maxCrossAxisWidth = style.maxWidth(avalidWidth: crossAxisWidth)
            minCrossAxisWidth = style.minWidth(avalidWidth: crossAxisWidth)
        }
        guard mainAxisWidth > 0 && crossAxisWidth > 0 else { return }

        var lineBoxs = [LineBox]()
        var prevLineBox: LineBox?
        var lineBox = createLineBox()

        var runBoxs = children
        var index = 0
        var box: RunBox

        let maxCrossAxisWidthWithBuffer = (maxCrossAxisWidth == nil ? nil : maxCrossAxisWidth! + maxCrossAxisWidthBuffer)
        /// 实际可用剩余宽度
        mainAxisWidth = min(mainAxisWidth, maxMainAxisWidth ?? mainAxisWidth)
        mainAxisWidth = max(mainAxisWidth, minMainAxisWidth ?? mainAxisWidth)
        crossAxisWidth = min(crossAxisWidth, maxCrossAxisWidthWithBuffer ?? crossAxisWidth)
        crossAxisWidth = max(crossAxisWidth, minCrossAxisWidth ?? crossAxisWidth)

        // 当前LineBox剩余的主轴长度
        var remainedMainAxisWidth = mainAxisWidth
        // 一共布局了多少纵轴长度
        var accumulatedCrossAxisWidth = CGFloat(0)

        // Min priority is bigger than max.
        while index < runBoxs.count {
            struct MaxHeightError: Error {}
            struct MaxLineError: Error {}
            struct NoWrapError: Error {}

            func beginNewLine() throws {
                // 设置了textOverflow表示最多只展示一行
                if isNoWrap {
                    throw NoWrapError()
                }
                lineBox.reflow()

                var value = accumulatedCrossAxisWidth + lineBox.crossAxisWidth
                if writingMode == .horizontalTB {
                    value += getActualLineSpacing(prevLine: prevLineBox, curLine: lineBox)
                }
                // 判断高度限制
                guard value ~<= crossAxisWidth else {
                    ownerRenderObject?.isContentScroll = true
                    throw MaxHeightError()
                }
                // 判断最大行数限制
                guard maxLineNoLimit || (maxLine > 0 && lineBoxs.count < maxLine - 1) else {
                    ownerRenderObject?.isContentScroll = true
                    throw MaxLineError()
                }

                accumulatedCrossAxisWidth = value

                lineBoxs.append(lineBox)
                prevLineBox = lineBox
                lineBox = self.createLineBox()
                remainedMainAxisWidth = mainAxisWidth
            }

            func doSplit() throws {
                switch box.split(mainAxisWidth: remainedMainAxisWidth, first: remainedMainAxisWidth == mainAxisWidth, context: nil) {
                // 最后一个 box 可以拆，拆完换行
                case .success(let lhs, let rhs):
                    runBoxs[index] = rhs
                    lineBox.append(runBox: lhs)

                    try beginNewLine()
                // 最后一个 box 可以拆，但当前行剩下的空间不够拆完的左半部分，先换行，继续拆
                case .failure(let lhs, let rhs):
                    // 一整行折行都失败了，需要直接退出流程，否则会死循环
                    if lineBox.runBoxs.isEmpty {
                        lineBox.append(runBox: lhs)
                        try beginNewLine()
                        if let value = rhs {
                            runBoxs[index] = value
                        } else {
                            index += 1
                        }
                    } else {
                        try beginNewLine()
                        runBoxs[index] = lhs
                        if let rhs = rhs {
                            runBoxs.insert(rhs, at: index + 1)
                        }
                    }
                // 最后一个 box 不可以拆，直接换行
                case .disable(let lhs, let rhs):
                    if !lineBox.runBoxs.isEmpty {
                        try beginNewLine()
                    }

                    lineBox.append(runBox: lhs)
                    // lhs 的宽度小于最大宽度，正常塞
                    if lhs.mainAxisWidth ~<= remainedMainAxisWidth {
                        remainedMainAxisWidth -= lhs.mainAxisWidth
                    }
                    // lhs 的宽度大于最大宽度，塞完以后(会被切割)直接换行
                    else {
                        try beginNewLine()
                    }

                    if let value = rhs {
                        runBoxs[index] = value
                    } else {
                        index += 1
                    }
                // 实际本行可以放的下，但因为换行符提前触发了 split，把 box 放入当前行，然后开启新一行
                case .breakLine:
                    remainedMainAxisWidth -= box.mainAxisWidth
                    lineBox.append(runBox: box)
                    index += 1

                    do { try beginNewLine() } catch { break }
                }
            }

            box = runBoxs[index]
            box.layoutIfNeeded(context: isInlineBlock ? nil : context)

            // 1.如果主轴是无限长度，是被嵌套的 inlineContainer 在预计算宽度，不可以计算折行
            // 2.否则inlineContainer box 需要优先判断换行符，如果是换行的话，直接进入 split 流程
            //   2.1.举例：Inline[Text, Text]，第一个Text是isLineBreak，则Inline也是isLineBreak，这时候第一个Text需要单独进行split，不能对两个Text整体进行split，因为第二个Text需要换行显示
            if mainAxisWidth != .greatestFiniteMagnitude, box.isLineBreak, box is InlineBlockContainerRunBox {
                do { try doSplit() } catch { break }
                continue
            }

            // 在一行内正常塞，允许 1 以内的误差
            if box.mainAxisWidth ~<= remainedMainAxisWidth {
                remainedMainAxisWidth -= box.mainAxisWidth
                lineBox.append(runBox: box)
                index += 1

                // 对于非 inlineContainer 的 box，如果是折行，会在正常排完自己以后开启新的一行
                if mainAxisWidth != .greatestFiniteMagnitude, box.isLineBreak {
                    do { try beginNewLine() } catch { break }
                }
                continue
            }

            // 当前行空间不够，开始折行
            do { try doSplit() } catch { break }
        }

        // Actual lineBoxs total cross width value.
        self.wholeLineCrossWidth = accumulatedCrossAxisWidth
        // 处理最后一行,此lineBox有以下几种可能：
        // 1.上面没有触发高度、行数限制、textOverflow，isContentScroll为false
        //   1.1.如果下面判断能展示下此lineBox，则isContentScroll为false
        //   1.2.如果下面判断不能展示此lineBox，则isContentScroll为true
        //   1.3.lineBox.runBoxs理论上会为空，beginNewLine后没有新的runBox需要处理
        // 2.上面触发了行数限制，则lineBox为限制的最后一行，isContentScroll为true；比如maxLine为2，则lineBox就是第2行
        //   2.1.下面会判断出在高度范围内，if self.wholeLineCrossWidth ~<= crossAxisWidth {...} 肯定为true
        // 3.上面触发了高度限制，则lineBox为刚好超出高度限制的第一行，isContentScroll为true；比如crossAxisWidth为200，则lineBox就是 > 200的第一行
        //   3.1.下面会判断出超出高度范围，if self.wholeLineCrossWidth ~<= crossAxisWidth {...} 肯定为false
        // 4.上面触发了textOverflow，isContentScroll为false，则lineBox就是第一行、最后一行
        if !lineBox.runBoxs.isEmpty {
            // 如果两个对象的地址相同，说明已经处理完了所有的runBoxs；否则对lineBox展示"省略号"
            if let leftBox = runBoxs.last, let rightBox = lineBox.runBoxs.last, leftBox !== rightBox {
                // 得到目前使用的宽度，上面的remainedMainAxisWidth在触发换行等时不准确
                var usedMainAxisWidth: CGFloat = 0; lineBox.runBoxs.forEach { usedMainAxisWidth += $0.mainAxisWidth }
                var remainedMainAxisWidth = mainAxisWidth - usedMainAxisWidth
                lineBox.truncatedIfNeeded(
                    context: isInlineBlock ? nil : LayoutContext(lineCamp: style.genContextLineCamp(context: context, maxLine: maxLine - lineBoxs.count)),
                    remainedMainAxisWidth: &remainedMainAxisWidth
                )
            } else {
                // truncatedIfNeeded内部已经执行了reflow
                lineBox.reflow()
            }
            self.wholeLineCrossWidth = accumulatedCrossAxisWidth + lineBox.crossAxisWidth
            if writingMode == .horizontalTB {
                self.wholeLineCrossWidth += getActualLineSpacing(prevLine: prevLineBox, curLine: lineBox)
            }
            if self.wholeLineCrossWidth ~<= crossAxisWidth {
                accumulatedCrossAxisWidth = self.wholeLineCrossWidth
                lineBoxs.append(lineBox)
            } else {
                // 实际要展示的内容比限制的纵轴长，表示内容没有展示完
                ownerRenderObject?.isContentScroll = true
                // 如果一行都没有，则展示至少一行
                if lineBoxs.isEmpty {
                    accumulatedCrossAxisWidth = crossAxisWidth
                }
                // 目前LKRichView定义：如果内容为4.5行，限制只展示4行，那么超出的0.5行也会被渲染出来；注意：accumulatedCrossAxisWidth并没有加这一行的高度
                lineBoxs.append(lineBox)
            }
        }

        // 得到最终主、纵轴多少宽度
        var finalMainAxisWidth = lineBoxs.reduce(0, { max($0, $1.mainAxisWidth) })
        var finalCrossAxisWidth = accumulatedCrossAxisWidth
        /// Deal with max and min at last.
        finalMainAxisWidth = min(finalMainAxisWidth, maxMainAxisWidth ?? finalMainAxisWidth)
        finalMainAxisWidth = max(finalMainAxisWidth, minMainAxisWidth ?? finalMainAxisWidth)

        // finalCrossAxisWidth按需调整：https://bytedance.feishu.cn/docx/AGUvd9zbao4QSsxZvg1cU34inAQ
        if let maxCrossAxisWidth = maxCrossAxisWidth, let maxCrossAxisWidthWithBuffer = maxCrossAxisWidthWithBuffer,
           ownerRenderObject?.isContentScroll == true, self.wholeLineCrossWidth > maxCrossAxisWidthWithBuffer {
            finalCrossAxisWidth = min(finalCrossAxisWidth, maxCrossAxisWidth)
        }

        finalCrossAxisWidth = max(finalCrossAxisWidth, minCrossAxisWidth ?? finalCrossAxisWidth)

        // 如果外部指定了 size，使用外部 size
        switch writingMode {
        case .horizontalTB:
            if isNumbericDefinited(style.storage.width) {
                finalMainAxisWidth = style.width(avalidWidth: avaliableMainAxisWidth)
                    - edges.left - edges.right
            }
            if isNumbericDefinited(style.storage.height) {
                finalCrossAxisWidth = style.height(avalidHeight: avaliableCrossAxisWidth)
                    - edges.top - edges.bottom
            }
            contentSize = .init(width: finalMainAxisWidth, height: finalCrossAxisWidth)
        case .verticalLR, .verticalRL:
            if isNumbericDefinited(style.storage.width) {
                finalMainAxisWidth = style.width(avalidWidth: avaliableCrossAxisWidth)
                    - edges.top - edges.bottom
            }
            if isNumbericDefinited(style.storage.height) {
                finalCrossAxisWidth = style.height(avalidHeight: avaliableMainAxisWidth)
                    - edges.left - edges.right
            }
            contentSize = .init(width: finalCrossAxisWidth, height: finalMainAxisWidth)
        }

        // 设置 ascent 和 descent
        if let lastLine = lineBoxs.last {
            ascent = accumulatedCrossAxisWidth - lastLine.baselineOrigin.y
            descent = finalCrossAxisWidth - ascent
        } else {
            ascent = finalCrossAxisWidth
            descent = 0
        }

        self.lineBoxs = lineBoxs
    }

    /// 执行此方法时，表示当前不是预排阶段；之前已经预排过：只有一个LineBox，把所有的children放在一行
    func split(mainAxisWidth: CGFloat, first: Bool, context: LayoutContext?) -> RunBoxSplitResult {
        if isInlineBlock {
            return .disable(lhs: self, rhs: nil)
        }

        var remainedWidth = mainAxisWidth
        let runboxs = children

        for (index, box) in runboxs.enumerated() {

            func doSplit(_ remainedWidth: CGFloat) -> RunBoxSplitResult {
                var prefix = Array(runboxs.prefix(upTo: index))
                var suffix = Array(runboxs.suffix(from: index + 1))
                var isNotSuccess = false
                let splitResult = box.split(mainAxisWidth: remainedWidth, first: first && (remainedWidth == mainAxisWidth), context: context)
                switch splitResult {
                // split 成功，分别在 prefix 末尾、suffix 首部插入
                case .success(let lhs, let rhs):
                    prefix.append(lhs)
                    suffix.insert(rhs, at: suffix.startIndex)
                // box 不可 split，判断自己是否是首位，若是则把自己放入 prefix；否则放入 suffix，在新的一行尝试排布
                // 如果自己不是首位，可以用在 split 的时候把自己放入 suffix 的方法来时间折行；
                // 如果是首位，则外面必须用 disable 或者 failure 的方式来处理
                case .disable(let lhs, let rhs), .failure(let lhs, let rhs):
                    var rhsList = [RunBox]()
                    if prefix.isEmpty {
                        prefix.append(box)
                        isNotSuccess = true
                    } else {
                        rhsList.append(lhs)
                    }
                    if let val = rhs {
                        rhsList.append(val)
                    }
                    suffix.insert(contentsOf: rhsList, at: suffix.startIndex)
                // 实际本行可以放的下，但是因为换行符提前触发了 split，把 box 放在 prefix
                case .breakLine:
                    prefix.append(box)
                }

                children = prefix
                layout(context: context)
                renderContextLength = children.reduce(0, { $0 + $1.renderContextLength })
                isSplit = true

                let rhs = InlineBlockContainerRunBox(
                    style: style,
                    avaliableMainAxisWidth: avaliableMainAxisWidth,
                    avaliableCrossAxisWidth: avaliableCrossAxisWidth,
                    renderContextLocation: renderContextLocation + renderContextLength,
                    children: suffix
                )
                rhs.ownerRenderObject = ownerRenderObject
                rhs.debugOptions = debugOptions
                rhs.layout(context: context)
                rhs.renderContextLength = rhs.children.reduce(0, { $0 + $1.renderContextLength })
                rhs.isSplit = true

                ownerRenderObject?.runBox.appendSplitVal(origin: self, lhs: self, rhs: rhs)

                if isNotSuccess {
                    if case .failure = splitResult {
                        return .failure(lhs: self, rhs: rhs)
                    } else {
                        return .disable(lhs: self, rhs: rhs)
                    }
                } else {
                    return .success(lhs: self, rhs: rhs)
                }
            }

            box.layoutIfNeeded(context: context)

            // inlineContainer box 需要优先判断换行符，如果是换行的话，直接进入 split 流程
            if box.isLineBreak, box is InlineBlockContainerRunBox {
                return doSplit(remainedWidth)
            }

            // 在一行内正常塞，允许 1 以内的误差
            var boxWidth = box.mainAxisWidth
            if index == 0 {
                boxWidth += edges.left
            }
            if index == runboxs.count - 1 {
                boxWidth += edges.right
            }
            if boxWidth ~<= remainedWidth {
                // 对于非 inlineContainer 的 box，如果是折行，会先排布自己，再触发 split
                if box.isLineBreak {
                    return doSplit(remainedWidth)
                }
                remainedWidth -= box.mainAxisWidth
                continue
            }

            // 当前行空间不够，开始折行
            return doSplit(remainedWidth)
        }

        // 如果父亲 inlineContainer 在 split 的时候，是有左右边距的，并且恰巧因为边距导致判定宽度不够
        // 从而进入 split 流程，则当前 inlineContainer 有可能会走到这里
        return .breakLine
    }

    func draw(_ paintInfo: PaintInfo) {
        if let renderObject = ownerRenderObject {
            StyleRenderer.render(
                style: style,
                paintInfo: paintInfo,
                renderObject: renderObject
            )
        }
        for lineBox in lineBoxs {
            lineBox.draw(paintInfo)
        }
    }

    func truncate(with tokenRunBox: TextRunBox, remainedMainAxisWidth: inout CGFloat) {
        guard let ownerLineBox = ownerLineBox, let lastLineBox = self.lineBoxs.last else { return }

        // 多行 || 自身全部清除都不足以展示token
        if self.lineBoxs.count > 1 || (self.mainAxisWidth + remainedMainAxisWidth) <= tokenRunBox.mainAxisWidth {
            remainedMainAxisWidth += self.mainAxisWidth
            ownerLineBox.runBoxs.removeLast()
            return
        }

        // 如果当前LineBox剩余的宽度不能展示下token，则需要对最后一个RunBox进行裁剪
        while let lastRunBox = lastLineBox.runBoxs.last, remainedMainAxisWidth < tokenRunBox.mainAxisWidth {
            let oldRemainedMainAxisWidth = remainedMainAxisWidth
            lastRunBox.truncate(with: tokenRunBox, remainedMainAxisWidth: &remainedMainAxisWidth)
            // 如果两次大小没有变化，则应该是遇到了异常情况，需要退出while循环
            if remainedMainAxisWidth <= oldRemainedMainAxisWidth { break }
        }
        // 修正lastLineBox.contentSize
        lastLineBox.reflow()
        // 修正self.contentSize
        self.contentSize.width = lastLineBox.mainAxisWidth
    }

    func getTiledInfos() -> [TiledInfo] {
        guard canRender() else { return [] }
        guard canTiledByLines() else {
            return [TiledInfo(runBoxs: [self], area: multiplication(size))]
        }
        return lineBoxs.map({ TiledInfo(runBoxs: $0.runBoxs, area: multiplication($0.size)) })
    }

    func selectionLineInfo() -> [(lineRect: CGRect, subRunBoxs: [RunBox], runBox: RunBox)] {
        if style.isBlockSelection {
            return []
        }
        return lineBoxs.map { ($0.globalRect, $0.runBoxs, self) }
    }

    private func positioningLines() {
        var start = globalContentOrigin
        switch writingMode {
        case .horizontalTB:
            // LineBox整体从顶部开始往下排
            start.y += contentSize.height - wholeLineCrossWidth
            var i = lineBoxs.count - 1
            while i >= 0 {
                let line = lineBoxs[i]
                switch mainAxisAlign {
                case .start, .end:
                    // FIXME: @qhy 根据l2r r2l适配start和end
                    line.origin = start
                case .left:
                    line.origin = start
                case .center:
                    line.origin = .init(x: start.x + (contentMainAxisWidth - line.mainAxisWidth) / 2, y: start.y)
                case .right:
                    line.origin = .init(x: start.x + contentMainAxisWidth - line.mainAxisWidth, y: start.y)
                }
                var prevLine: LineBox?
                if i > 0 {
                    prevLine = lineBoxs[i - 1]
                }
                start.y += line.crossAxisWidth + getActualLineSpacing(prevLine: prevLine, curLine: line)
                i -= 1
            }
        case .verticalLR:
            start.x += edges.left
            start.x += crossAxisWidth - wholeLineCrossWidth
            lineBoxs.reversed().forEach { line in
                switch mainAxisAlign {
                case .start, .end:
                    // FIXME: @qhy 根据l2r r2l适配start和end
                    line.origin = start
                case .left:
                    line.origin = start
                case .center:
                    line.origin = .init(x: start.x, y: start.y + (contentMainAxisWidth - line.mainAxisWidth) / 2)
                case .right:
                    line.origin = .init(x: start.x, y: start.y + contentMainAxisWidth - line.mainAxisWidth)
                }
                start.x += line.crossAxisWidth
            }
        case .verticalRL:
            start.x += edges.right
            start.x += crossAxisWidth - wholeLineCrossWidth
            lineBoxs.reversed().forEach { line in
                switch mainAxisAlign {
                case .start, .end:
                    // FIXME: @qhy 根据l2r r2l适配start和end
                    line.origin = start
                case .left:
                    line.origin = start
                case .center:
                    line.origin = .init(x: start.x, y: start.y + (contentMainAxisWidth - line.mainAxisWidth) / 2)
                case .right:
                    line.origin = .init(x: start.x, y: start.y + contentMainAxisWidth - line.mainAxisWidth)
                }
                start.x += line.crossAxisWidth
            }
        }
    }

    private func reset() {
        ascent = 0
        descent = 0
        leading = 0
        contentSize = .zero
        renderContextLength = 0
        lineBoxs = []
        wholeLineCrossWidth = 0
    }

    @inline(__always)
    private func createLineBox() -> LineBox {
        return LineBox(style: style, debugOptions: debugOptions)
    }

    private func getActualLineSpacing(prevLine: LineBox?, curLine: LineBox) -> CGFloat {
        guard let prevLine = prevLine else {
            return 0
        }
        return max(style.lineHeight - prevLine.descent - prevLine.leading - curLine.ascent, 1)
    }
}
