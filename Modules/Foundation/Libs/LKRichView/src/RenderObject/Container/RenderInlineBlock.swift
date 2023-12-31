//
//  RenderInlineBlock.swift
//  LKRichView
//
//  Created by 白言韬 on 2021/8/2.
//

import UIKit
import Foundation

class RenderInlineBlock: RenderBlock {

    override var isRenderBlock: Bool {
        isNeedRender
    }
    override var isRenderInline: Bool {
        isNeedRender
    }

    override func layout(_ size: CGSize, context: LayoutContext?) -> CGSize {
        if let size = cachedLayoutSize(size, context: context) {
            return size
        }

        if isChildrenInline {
            let container = layoutInline(size, isInlineBlock: true, context: context)
            return container.size
        }

        let container = layoutBlock(size, isInlineBlock: true, context: context)
        return container.size
    }

    override func paint(_ paintInfo: PaintInfo) {
        switch runBox {
        case .normal(let unwrappedBox):
            unwrappedBox?.draw(paintInfo)
        case .split(let runBoxs):
            runBoxs.forEach({ $0.draw(paintInfo) })
        }
    }
}
