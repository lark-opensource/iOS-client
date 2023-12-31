//
//  LKTextIndicatorElement.swift
//  LKRichView
//
//  Created by 李勇 on 2022/6/24.
//

import Foundation
import UIKit

/// 占位Tag，内部使用，没有特殊逻辑
enum PlaceholderTag: Int8, LKRichElementTag {
    case inlineBlock = -30

    var typeID: Int8 { rawValue }
}

/// 有点像UITableViewCell.accessoryType = .disclosureIndicator的样式，左边的文字可定制，右侧的图标也可定制
/// 1、文字 、图标垂直居中
/// 2、不允许添加子Element，内容固定
/// 3、设计为LKBlockElement，从新行开始展示，宽度默认铺全父视图
public final class LKTextIndicatorElement: LKBlockElement {
    #if DEBUG
    public override var name: String {
        return "#textIndicator"
    }
    #endif

    public init(tagName: LKRichElementTag, text: LKTextElement, img: LKImgElement) {
        super.init(tagName: tagName, style: LKRichStyle().width(.percent(100)))
        // 文字、图片，在LineBox内垂直居中
        text.style.verticalAlign(.middle)
        // LKImgElement的getDefaultString方法中有defaultString判空的assert
        img.style.verticalAlign(.middle)
        img.defaultString = "[image]"
        // 中间插入一个0宽度，100%父高度的空InlineBlock，撑开LineBox到父高度
        let inlineBlock = LKInlineBlockElement(tagName: PlaceholderTag.inlineBlock)
        inlineBlock.style.verticalAlign(.middle).height(.percent(100))
        // 用self调用会触发assertionFailure
        super.children([text, inlineBlock, img])
    }

    override func createRenderer(cssEngine: CSSStyleEngine? = nil) -> RenderObject {
        // 自身style和样式表style进行合并，得到最终要展示的style
        let finalStyle = mergeRenderStyle(cssEngine: cssEngine, node: self)
        let textIndicator = RenderTextIndicator(nodeType: type, renderStyle: finalStyle, ownerElement: self)
        subElements.filter { $0.shouldCreateRenderer() }.forEach {
            textIndicator.appendChild($0.createRenderer(cssEngine: cssEngine))
        }
        return textIndicator
    }

    /// 外部不能添加child
    public override func addChild(_ element: Node) -> Self {
        assertionFailure()
        return self
    }

    public override func children(_ elements: [Node]) -> Self {
        assertionFailure()
        return self
    }
}
