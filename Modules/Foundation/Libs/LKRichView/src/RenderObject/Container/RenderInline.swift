//
//  RenderInline.swift
//  LKRichView
//
//  Created by 白言韬 on 2021/8/2.
//

import UIKit
import Foundation

class RenderInline: RenderObject {
    var prevLayoutSize: CGSize = .zero

    override var isRenderBlock: Bool {
        false
    }
    override var isRenderInline: Bool {
        isNeedRender
    }

    override func layout(_ size: CGSize, context: LayoutContext?) -> CGSize {
        if let size = cachedLayoutSize(size, context: context) {
            return size
        }
        let container = layoutInline(size, isInlineBlock: false, context: context)
        return container.size
    }

    func cachedLayoutSize(_ size: CGSize, context: LayoutContext?) -> CGSize? {
        guard size.width != 0, size.height != 0 else {
            _linesCount = 0
            runBox = .normal(nil)
            contentSize = .zero
            isContentScroll = false
            return .zero
        }
        if prevLayoutSize != .zero, prevLayoutSize == size {
            return boxRect.size
        }
        self.prevLayoutSize = size
        return nil
    }

    func layoutInline(_ size: CGSize, isInlineBlock: Bool, container: InlineBlockContainerRunBox? = nil, context: LayoutContext?) -> InlineBlockContainerRunBox {
        // 主轴、纵轴宽度
        let writingMode = renderStyle.writingMode
        let avaliableMainAxisWidth = size.mainAxisWidth(writingMode: writingMode)
        let avaliableCrossAxisWidth = size.crossAxisWidth(writingMode: writingMode)
        let container = container ?? InlineBlockContainerRunBox(
            style: renderStyle,
            avaliableMainAxisWidth: avaliableMainAxisWidth,
            avaliableCrossAxisWidth: avaliableCrossAxisWidth,
            renderContextLocation: renderContextLocation
        )
        container.isInlineBlock = isInlineBlock
        container.ownerRenderObject = self
        container.debugOptions = debugOptions
        layoutChildren(
            avalidWidth: avaliableMainAxisWidth,
            avalidHeight: avaliableCrossAxisWidth,
            container: container,
            context: context
        )
        container.layoutIfNeeded(context: LayoutContext(lineCamp: renderStyle.genContextLineCamp(context: context)))
        _linesCount = container.lineBoxs.count
        // 触发container.origin的didSet方法，排列子RunBox的origin
        container.origin = boxOrigin
        renderContextLength = container.renderContextLength
        contentSize = container.contentSize

        runBox = .normal(container)
        return container
    }

    private func layoutChildren(avalidWidth: CGFloat, avalidHeight: CGFloat, container: InlineBlockContainerRunBox, context: LayoutContext?) {
        // children渲染的可用宽度，需要 - padding - border
        let childAvaliableSize = CGSize(
            width: renderStyle.calculateWidthWithEdge(avalidWidth: avalidWidth),
            height: renderStyle.calculateHeightWithEdge(avalidHeight: avalidHeight)
        )
        // 得到children渲染结束的位置
        var location = renderContextLocation
        for child in children {
            child.renderContextLocation = location
            if !child.isRenderBlock, child.isRenderInline {
                // RenderInline，不限制宽度，后续折行
                _ = child.layout(CGSize(width: .greatestFiniteMagnitude, height: childAvaliableSize.height), context: context)
            } else {
                // RenderInlineBlock，限制宽度
                _ = child.layout(childAvaliableSize, context: context)
            }
            location += child.renderContextLength
        }
        container.renderContextLength = location - renderContextLocation
        var runBoxs: [RunBox] = []
        for renderObject in children {
            if let renderRunBox = (renderObject as? RenderInline)?.createRunBox() {
                switch renderRunBox {
                case .normal(let unwrapped):
                    if let runBox = unwrapped {
                        runBoxs.append(runBox)
                    }
                case .split(let splitRunBoxs):
                    runBoxs += splitRunBoxs
                }
            }
        }
        container.children = runBoxs
    }

    override func paint(_ paintInfo: PaintInfo) {
        switch runBox {
        case .normal(let unwrappedBox):
            unwrappedBox?.draw(paintInfo)
        case .split(let runBoxs):
            runBoxs.forEach({ $0.draw(paintInfo) })
        }
    }

    func createRunBox() -> RenderRunBox? {
        return runBox
    }
}
