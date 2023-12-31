//
//  RenderTextIndicator.swift
//  LKRichView
//
//  Created by 李勇 on 2022/6/24.
//

import Foundation
import UIKit

/// layout中需要创建自定义的RunBox，则需要自定义RenderObject
class RenderTextIndicator: RenderBlock {
    override func layout(_ size: CGSize, context: LayoutContext?) -> CGSize {
        // 如果size入参是zero，说明当前LKRichView没有展示，此时不需要进行布局计算
        guard size != .zero else { return .zero }
        if prevLayoutSize != .zero, prevLayoutSize == size { return boxRect.size }
        self.prevLayoutSize = size

        let mainAxisWidth = size.mainAxisWidth(writingMode: renderStyle.writingMode)
        let crossAxisWidth = size.crossAxisWidth(writingMode: renderStyle.writingMode)
        let textIndicatorRunBox = TextIndicatorContainerRunBox(
            style: renderStyle,
            avaliableMainAxisWidth: mainAxisWidth,
            avaliableCrossAxisWidth: crossAxisWidth,
            renderContextLocation: renderContextLocation
        )
        // 先对子RunBox进行layout，得到size信息
        _ = layoutInline(size, isInlineBlock: false, container: textIndicatorRunBox, context: context)
        return textIndicatorRunBox.size
    }
}

class TextIndicatorContainerRunBox: InlineBlockContainerRunBox {
    override var origin: CGPoint {
        didSet {
            // 如果LineBox数量超过一个，说明宽度很窄，此时文字、图片已不在一行，不处理
            guard self.lineBoxs.count == 1, let runBox = self.children.last as? ImgRunBox else { return }

            // 图片放到最右侧，目前style中没有右对齐的属性，需要自己适配
            runBox.origin = CGPoint(x: contentSize.width - runBox.contentSize.width, y: runBox.origin.y)
        }
    }
}
