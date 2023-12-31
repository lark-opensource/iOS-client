//
//  RenderAttachment.swift
//  LKRichView
//
//  Created by qihongye on 2020/1/12.
//

import UIKit
import Foundation

final class RenderAttachment: RenderInlineBlock {

    private let attachment: LKRichAttachment

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

    init(nodeType: Node.TypeEnum, renderStyle: LKRenderRichStyle, ownerElement: LKRichElement?, attachment: LKRichAttachment) {
        self.attachment = attachment
        super.init(nodeType: nodeType, renderStyle: renderStyle, ownerElement: ownerElement)
    }

    override func appendChild(_ child: RenderObject) { }

    override func removeChild(idx: Int) { }

    override func layout(_ size: CGSize, context: LayoutContext?) -> CGSize {
        if let size = cachedLayoutSize(size, context: context) {
            return size
        }

        let runBox = AttachmentRunBox(
            style: renderStyle,
            attachment: attachment,
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
        if case .normal(let unwrappedBox) = runBox, let box = unwrappedBox {
            box.draw(paintInfo)
        }
    }
}
