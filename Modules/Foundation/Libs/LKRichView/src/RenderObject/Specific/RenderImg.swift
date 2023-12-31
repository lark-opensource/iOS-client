//
//  RenderImg.swift
//  LKRichView
//
//  Created by qihongye on 2019/10/11.
//

import UIKit
import Foundation

final class RenderImg: RenderInlineBlock {

    var image: CGImage?

    override var isRenderBlock: Bool {
        isNeedRender
    }

    override var isRenderInline: Bool {
        isNeedRender
    }

    override var isRenderFloat: Bool {
        false
    }

    override var isChildrenBlock: Bool {
        false
    }

    override var isChildrenInline: Bool {
        false
    }

    init(nodeType: Node.TypeEnum, renderStyle: LKRenderRichStyle, ownerElement: LKRichElement?, image: CGImage? = nil) {
        self.image = image
        super.init(nodeType: nodeType, renderStyle: renderStyle, ownerElement: ownerElement)
    }

    override func appendChild(_ child: RenderObject) { }

    override func removeChild(idx: Int) { }

    override func layout(_ size: CGSize, context: LayoutContext?) -> CGSize {
        if let size = cachedLayoutSize(size, context: context) {
            return size
        }
        let runBox = ImgRunBox(
            style: renderStyle,
            img: image,
            avaliableMainAxisWidth: size.mainAxisWidth(writingMode: renderStyle.writingMode),
            avaliableCrossAxisWidth: size.crossAxisWidth(writingMode: renderStyle.writingMode),
            renderContextLocation: renderContextLocation
        )
        runBox.ownerRenderObject = self
        runBox.layoutIfNeeded(context: context)
        renderContextLength = runBox.renderContextLength
        contentSize = runBox.size
        self.runBox = .normal(runBox)
        return runBox.size
    }

    override func paint(_ paintInfo: PaintInfo) {
        guard case .normal(let unwrappedBox) = runBox, let box = unwrappedBox else { return }
        let context = paintInfo.graphicsContext
        context.saveGState()
        box.draw(paintInfo)
        context.restoreGState()
    }
}
