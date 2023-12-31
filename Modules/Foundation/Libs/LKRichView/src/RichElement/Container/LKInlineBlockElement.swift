//
//  LKInlineBlockElement.swift
//  LKRichView
//
//  Created by 白言韬 on 2021/8/3.
//

import Foundation

var _defaultInlinBlockStyleProperties: [StyleProperty] = {
    [StyleProperty(name: .display, value: LKRichStyleValue<Display>(.value, .inlineBlock))]
}()

public final class LKInlineBlockElement: LKRichElement {

    public struct InlineConfig {
        /// getDefaultString时需要额外附加的Attributes
        public let extraAttributes: [NSAttributedString.Key: Any]

        public init(_ extraAttributes: [NSAttributedString.Key: Any] = [:]) {
            self.extraAttributes = extraAttributes
        }
    }

    #if DEBUG
    public override var name: String {
        return "#inlineBlock"
    }
    #endif

    public override var defaultStyleProperties: StyleProperties {
        StyleProperties(_defaultInlinBlockStyleProperties)
    }

    override var isBlock: Bool {
        if style.display == nil {
            return true
        }
        return super.isBlock
    }

    override var isInline: Bool {
        if style.display == nil {
            return true
        }
        return super.isInline
    }

    private var config: InlineConfig?

    public convenience init( id: String = "",
                      tagName: LKRichElementTag,
                      config: InlineConfig,
                      classNames: [String] = [],
                      style: LKRichStyle = LKRichStyle()) {
        self.init(id: id, tagName: tagName, classNames: classNames, style: style)
        self.config = config
    }

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
        let cloned = LKInlineBlockElement(
            id: self.id,
            tagName: self.tagName,
            classNames: self.classNames,
            /// swiftlint:disable:next force_cast
            style: self.style.copy() as! LKRichStyle
        )
        return copyTo(node: cloned)
    }

    override func defaultStringAttributes() -> [NSAttributedString.Key : Any] {
        return self.config?.extraAttributes ?? [:]
    }
// 不需要额外的copyTo能力，暂时注掉。
//    override func copyTo(node: Node) -> Node {
//        return super.copyTo(node: node)
//    }
}
