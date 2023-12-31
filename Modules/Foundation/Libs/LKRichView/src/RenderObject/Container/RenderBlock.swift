//
//  RenderBlock.swift
//  LKRichView
//
//  Created by 白言韬 on 2021/8/2.
//

import UIKit
import Foundation

class RenderBlock: RenderInline {
    override var isRenderBlock: Bool {
        isNeedRender
    }
    override var isRenderInline: Bool {
        false
    }

    override func layout(_ size: CGSize, context: LayoutContext?) -> CGSize {
        if let size = cachedLayoutSize(size, context: context) {
            return size
        }

        if isChildrenInline {
            let container = layoutInline(size, isInlineBlock: false, context: context)
            return container.size
        }

        if isChildrenBlock || children.isEmpty { // 空Block需要由max/min W/H决策大小
            let container = layoutBlock(size, isInlineBlock: false, context: context)
            return container.size
        }

        // 兜底逻辑，正常情况下，不会走到这个return
        return CGSize(
            width: renderStyle.calculateWidthWithEdge(avalidWidth: size.width),
            height: renderStyle.calculateHeightWithEdge(avalidHeight: size.height)
        )
    }

    override func cachedLayoutSize(_ size: CGSize, context: LayoutContext?) -> CGSize? {
        if prevLayoutSize != .zero, prevLayoutSize == size {
            return boxRect.size
        }
        self.prevLayoutSize = size
        return nil
    }

    func layoutBlock(_ size: CGSize, isInlineBlock: Bool, container: BlockContainerRunBox? = nil, context: LayoutContext?) -> BlockContainerRunBox {
        let writingMode = renderStyle.writingMode
        let container = container ?? BlockContainerRunBox(
            style: renderStyle,
            avaliableMainAxisWidth: size.mainAxisWidth(writingMode: writingMode),
            avaliableCrossAxisWidth: size.crossAxisWidth(writingMode: writingMode),
            renderContextLocation: renderContextLocation
        )
        container.isInlineBlock = isInlineBlock
        container.ownerRenderObject = self
        container.debugOptions = debugOptions
        container.layoutIfNeeded(
            context: LayoutContext(
                lineCamp: renderStyle.genContextLineCamp(context: context)
            )
        )
        _linesCount = container.allInlienChildrenLinesCount
        // 触发container.origin的didSet方法，排列子RunBox的origin
        container.origin = boxOrigin
        runBox = .normal(container)

        renderContextLength = container.renderContextLength
        contentSize = container.contentSize
        return container
    }

    override func paint(_ paintInfo: PaintInfo) {
        switch runBox {
        case .normal(let runbox):
            runbox?.draw(paintInfo)
        case .split(let runboxs):
            for runbox in runboxs {
                runbox.draw(paintInfo)
            }
        }
    }
}
