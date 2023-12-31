//
//  LKInlineElement.swift
//  LKRichView
//
//  Created by 白言韬 on 2021/8/3.
//

import Foundation

public final class LKInlineElement: LKRichElement {

    /// Inline相关配置
    public struct InlineConfig {
        /// getDefaultString时需要额外附加的Attributes
        public let extraAttributes: [NSAttributedString.Key: Any]

        public init(_ extraAttributes: [NSAttributedString.Key: Any] = [:]) {
            self.extraAttributes = extraAttributes
        }
    }

    private var config: InlineConfig?

    private static var _defaultInlineStyleProperties: [StyleProperty] = {
        [StyleProperty(name: .display, value: LKRichStyleValue<Display>(.value, .inline))]
    }()

    #if DEBUG
    public override var name: String {
        return "#inline"
    }
    #endif

    public override var defaultStyleProperties: StyleProperties {
        StyleProperties(Self._defaultInlineStyleProperties)
    }

    override var isInline: Bool {
        if style.display == nil {
            return true
        }
        return super.isInline
    }

    public convenience init( id: String = "",
                             tagName: LKRichElementTag,
                             classNames: [String] = [],
                             config: InlineConfig,
                             style: LKRichStyle = LKRichStyle()) {
        self.init(id: id, tagName: tagName, classNames: classNames, style: style)
        self.config = config
    }

    public override init(
        id: String = "",
        tagName: LKRichElementTag,
        classNames: [String] = [],
        style: LKRichStyle = LKRichStyle()) {
        super.init(id: id, tagName: tagName, classNames: classNames, style: style)
    }

    @discardableResult
    public override func addChild(_ element: Node) -> Self {
        if element.isInline { super.addChild(element) }
        return self
    }

    public override func shouldCreateRenderer() -> Bool {
        true
    }

    @discardableResult
    public override func children(_ elements: [Node]) -> Self {
        super.children(elements.filter { $0.isInline })
        return self
    }

    public override func copy() -> Any {
        let cloned = LKInlineElement(
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
// 不需要，保留注释是为了提醒如果有必要需要override此方法。
//    override func copyTo(node: Node) -> Node {
//        return super.copyTo(node: node)
//    }
}
