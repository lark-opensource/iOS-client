//
//  BlockContainerRunBox.swift
//  LKRichView
//
//  Created by qihongye on 2020/2/2.
//

import UIKit
import Foundation

class BlockContainerRunBox: RunBox, ContainerRunBox {

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

    var isInlineBlock = false

    // MARK: - origin

    var origin: CGPoint = .zero {
        didSet {
            positionintChildren(dx: origin.x - oldValue.x, dy: origin.y - oldValue.y)
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

    // MARK: - width

    var mainAxisWidth: CGFloat {
        style.calculateMainAxisWidth(contentSize: contentSize)
    }
    var contentMainAxisWidth: CGFloat {
        contentSize.mainAxisWidth(writingMode: writingMode)
    }
    var crossAxisWidth: CGFloat {
        style.calculateCrossAxisWidth(contentSize: contentSize)
    }
    var contentCrossAxisWidth: CGFloat {
        contentSize.crossAxisWidth(writingMode: writingMode)
    }

    // MARK: - size

    var ascent: CGFloat {
        contentCrossAxisWidth
    }
    let descent: CGFloat = 0
    let leading: CGFloat = 0
    private(set) var contentSize: CGSize = .zero
    var edges: UIEdgeInsets
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
    private let avaliableMainAxisWidth: CGFloat
    private let avaliableCrossAxisWidth: CGFloat

    var children: [RunBox] = []

    private(set) var allInlienChildrenLinesCount = 0

    init(style: RenderStyleOM,
         avaliableMainAxisWidth: CGFloat,
         avaliableCrossAxisWidth: CGFloat,
         renderContextLocation: Int
    ) {
        self.style = style
        self.avaliableMainAxisWidth = avaliableMainAxisWidth
        self.avaliableCrossAxisWidth = avaliableCrossAxisWidth
        self._renderContextLocation = renderContextLocation
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

        guard let ownerRenderObject = ownerRenderObject else {
            self.contentSize = .zero
            return
        }

        var avaliableSize: CGSize
        switch writingMode {
        case .horizontalTB:
            avaliableSize = CGSize(
                width: style.calculateWidthWithEdge(avalidWidth: avaliableMainAxisWidth),
                height: style.calculateHeightWithEdge(avalidHeight: avaliableCrossAxisWidth)
            )
        case .verticalLR, .verticalRL:
            avaliableSize = CGSize(
                width: style.calculateWidthWithEdge(avalidWidth: avaliableCrossAxisWidth),
                height: style.calculateHeightWithEdge(avalidHeight: avaliableMainAxisWidth)
            )
        }
        let maxWidth = style.maxWidth(avalidWidth: avaliableSize.width)
        let maxHeight = style.maxHeight(avalidHeight: avaliableSize.height)
        let minWidth = style.minWidth(avalidWidth: avaliableSize.width)
        let minHeight = style.minHeight(avalidHeight: avaliableSize.height)
        let maxHeightBuffer = debugOptions?.maxHeightBuffer ?? 0
        let maxHeightWithBuffer = (maxHeight == nil ? nil : maxHeight! + maxHeightBuffer)

        avaliableSize.width = style.width(avalidWidth: avaliableSize.width)
        avaliableSize.height = style.height(avalidHeight: avaliableSize.height)

        if let maxWidth = maxWidth, avaliableSize.width > maxWidth {
            avaliableSize.width = maxWidth
        }
        if let minWidth = minWidth, avaliableSize.width < minWidth {
            avaliableSize.width = minWidth
        }
        if let value = maxHeightWithBuffer, avaliableSize.height > value {
            // 给子节点布局时，需要给超过 maxHeight 的值，否则 blockContainer 会以为子节点正好排的下
            avaliableSize.height = value * 1.5
        }

        var computeWidth: CGFloat = 0
        var computeHeight: CGFloat = 0
        var childVerticalOffsets: [CGFloat] = []
        var topChild: RenderObject?

        let maxLine = calcMaxLine(style: style, context: context)
        if maxLine == 0 {
            return
        }
        allInlienChildrenLinesCount = 0

        var location = renderContextLocation
        for child in ownerRenderObject.children {
            if let maxHeightWithBuffer = maxHeightWithBuffer, computeHeight >= maxHeightWithBuffer {
                break
            }
            child.renderContextLocation = location
            let size = child.layout(avaliableSize, context: LayoutContext(
                lineCamp: style.genContextLineCamp(context: context, maxLine: maxLine - allInlienChildrenLinesCount)
            ))
            // 这里inline-block和block是相同的逻辑：单独另起一行，和Web标准保持一致
            let childOffset = size.height + computeMarginSize(top: topChild, current: child)
            childVerticalOffsets.append(childOffset)
            computeWidth = max(computeWidth, size.width)
            computeHeight += childOffset
            topChild = child
            location += child.renderContextLength
            allInlienChildrenLinesCount += (child.isRenderBlock && child.isRenderInline) ? 1 : child.linesCount
            if maxLine > 0, allInlienChildrenLinesCount >= maxLine {
                break
            }
        }
        renderContextLength = location - renderContextLocation

        var children: [RunBox] = []
        for i in 0..<childVerticalOffsets.count {
            let renderObject = ownerRenderObject.children[i]
            if renderObject.isRenderBlock,
               case let .normal(runBox) = renderObject.runBox,
               let runbox = runBox {
                children.append(runbox)
            } else {
                assertionFailure()
            }
        }
        self.children = children

        if (isInlineBlock && !isNumbericDefinited(style.storage.width))
            || style.storage.width.type == .auto {
            avaliableSize.width = computeWidth
        }

        if !isNumbericDefinited(style.storage.height) {
            avaliableSize.height = computeHeight
        }

        if let maxWidth = maxWidth, avaliableSize.width > maxWidth {
            avaliableSize.width = maxWidth
            ownerRenderObject.isContentScroll = true
        }
        if let maxHeight = maxHeight, let maxHeightWithBuffer = maxHeightWithBuffer, avaliableSize.height > maxHeightWithBuffer {
            avaliableSize.height = maxHeight
            ownerRenderObject.isContentScroll = true
        }
        if let minWidth = minWidth, avaliableSize.width < minWidth {
            avaliableSize.width = minWidth
        }
        if let minHeight = minHeight, avaliableSize.height < minHeight {
            avaliableSize.height = minHeight
        }

        var contentHeight = avaliableSize.height
        assert(self.children.count == childVerticalOffsets.count)
        for i in 0..<min(self.children.count, childVerticalOffsets.count) {
            contentHeight -= childVerticalOffsets[i]
            let child = self.children[i]
            child.origin = CGPoint(
                x: globalOrigin.x + edges.left,
                y: globalOrigin.y + edges.bottom + contentHeight
            )
        }

        self.contentSize = avaliableSize
    }

    func split(mainAxisWidth: CGFloat, first: Bool, context: LayoutContext?) -> RunBoxSplitResult {
        return .disable(lhs: self, rhs: nil)
    }

    func draw(_ paintInfo: PaintInfo) {
        if let renderObject = ownerRenderObject {
            StyleRenderer.render(style: style, paintInfo: paintInfo, renderObject: renderObject)
            #if DEBUG
            let debug = paintInfo.debugOptions?.debug ?? false
            let context = paintInfo.graphicsContext
            if debug {
                context.saveGState()
                drawDebugLines(context, renderObject.boxRect)
                context.restoreGState()
            }
            #endif
        }
        for child in children {
            child.draw(paintInfo)
        }
    }

    /// Block是一个整体，没办法进行拆分，所以truncate的逻辑比较简单：删除自身
    func truncate(with tokenRunBox: TextRunBox, remainedMainAxisWidth: inout CGFloat) {
        guard let ownerLineBox = ownerLineBox else { return }

        remainedMainAxisWidth += self.mainAxisWidth
        ownerLineBox.runBoxs.removeLast()
    }

    func getTiledInfos() -> [TiledInfo] {
        guard canRender() else { return [] }
        guard canTiledByLines() else {
            return [TiledInfo(runBoxs: [self], area: multiplication(size))]
        }
        return children.flatMap({ $0.getTiledInfos() })
    }

    func selectionLineInfo() -> [(lineRect: CGRect, subRunBoxs: [RunBox], runBox: RunBox)] {
        if style.isBlockSelection {
            return []
        }
        return children.map { ($0.globalRect, [$0], self) }
    }
}

fileprivate extension BlockContainerRunBox {
    private func positionintChildren(dx: CGFloat, dy: CGFloat) {
        for child in children {
            /// origin 要使用全局坐标
            child.origin = CGPoint(
                x: child.origin.x + dx,
                y: child.origin.y + dy
            )
        }
    }

    private func computeMarginSize(top: RenderObject?, current: RenderObject) -> CGFloat {
        guard let top = top else {
            return current.renderStyle.margin.top
        }
        let marginBottom = top.renderStyle.margin.bottom
        let marginTop = current.renderStyle.margin.top

        if (marginBottom >= 0 && marginTop >= 0)
            || (marginBottom <= 0 && marginTop <= 0) {
            return max(marginBottom, marginTop)
        }
        return marginBottom + marginTop
    }
}

/// - returns maxLine.
/// - description:
/// While maxLine == -1, it means there is no limit for line count. And maxLine cannot be less than -1.
/// While maxLine == 0, it means there is no left line count.
/// While maxLine > 0, it means there is maxLine left.
func calcMaxLine(style: RenderStyleOM, context: LayoutContext?) -> Int {
    if let maxLine = style.lineCamp?.maxLine, maxLine > 0 {
        return maxLine
    }
    return max(context?.lineCamp?.maxLine ?? -1, -1)
}
