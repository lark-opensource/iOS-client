//
//  LKBlockElement.swift
//  LKRichView
//
//  Created by 白言韬 on 2021/8/3.
//

import UIKit
import Foundation

public class LKBlockElement: LKRichElement {
    private static var _defaultBlockStyleProperties: [StyleProperty] = {
        [StyleProperty(name: .display, value: LKRichStyleValue<Display>(.value, .block))]
    }()

    #if DEBUG
    public override var name: String {
        return "#block"
    }
    #endif

    public override var defaultStyleProperties: StyleProperties {
        StyleProperties(Self._defaultBlockStyleProperties)
    }

    override var isBlock: Bool {
        if style.display == nil {
            return true
        }
        return super.isBlock
    }

    /// 用于选区。当该值为 true 时，选区在取本元素的 defaultStr 时，会在末尾加一个 \n
    public var isLineBreak = false

    public override init(
        id: String = "",
        tagName: LKRichElementTag,
        classNames: [String] = [],
        style: LKRichStyle = LKRichStyle()
    ) {
        super.init(id: id, tagName: tagName, classNames: classNames, style: style)
    }

    public override func shouldCreateRenderer() -> Bool {
        true
    }

    @discardableResult
    public override func addChild(_ element: Node) -> Self {
        guard let first = subElements.first else {
            super.addChild(element)
            return self
        }
        // 如果第一个是inlineblock，那么后面只能增加inline。
        // 要么全都是纯的block，要么都是inline
        if first.isInline, element.isInline {
            super.addChild(element)
            return self
        }
        if first.isBlock, element.isBlock {
            super.addChild(element)
            return self
        }
        return self
    }

    public override func copy() -> Any {
        let cloned = LKBlockElement(
            id: self.id,
            tagName: self.tagName,
            classNames: self.classNames,
            /// swiftlint:disable:next force_cast
            style: self.style.copy() as! LKRichStyle
        )
        return copyTo(node: cloned)
    }

    override func copyTo(node: Node) -> Node {
        if let node = node as? LKBlockElement {
            node.isLineBreak = self.isLineBreak
        }
        return super.copyTo(node: node)
    }

    override func getDefaultString() -> NSMutableAttributedString {
        let attr = super.getDefaultString()
        if isLineBreak, attr.string.last != "\n" {
            attr.append(NSAttributedString(string: "\n"))
        }
        return attr
    }
}
