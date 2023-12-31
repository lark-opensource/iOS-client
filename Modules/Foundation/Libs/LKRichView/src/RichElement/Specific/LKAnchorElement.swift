//
//  LKAnchorElement.swift
//  LKRichView
//
//  Created by qihongye on 2021/9/13.
//

import UIKit
import Foundation

/// Anchor相关配置
public struct AnchorConfig {
    /// getDefaultString时需要额外附加的Attributes
    public let extraAttributes: [NSAttributedString.Key: Any]

    public init(_ extraAttributes: [NSAttributedString.Key: Any] = [:]) {
        self.extraAttributes = extraAttributes
    }
}

final public class LKAnchorElement: LKRichElement {
    private static var _styleProperties: [StyleProperty] = {
        [
            StyleProperty(name: .display, value: LKRichStyleValue<Display>(.value, .inline)),
            StyleProperty(name: .color, value: LKRichStyleValue<UIColor>(.value, .blue)),
            StyleProperty(
                name: .textDecoration,
                value: LKRichStyleValue<TextDecoration>(
                    .value, .init(line: .underline, style: .solid, thickness: 1, color: .blue)
                )
            )
        ]
    }()

    #if DEBUG
    public override var name: String {
        return "#anchor"
    }
    #endif

    public override var type: Node.TypeEnum {
        if text.isEmpty, !subElements.isEmpty {
            return .container
        }
        return .text
    }
    public override var tag: Int8 {
        self.tagName.typeID
    }
    override var isInline: Bool {
        if style.display == nil {
            return true
        }
        return super.isInline
    }

    public var text: String
    public var href: String?

    public override var defaultStyleProperties: StyleProperties {
        StyleProperties(Self._styleProperties)
    }

    private let config: AnchorConfig

    public init(
        id: String = "",
        tagName: LKRichElementTag,
        classNames: [String] = [],
        style: LKRichStyle = LKRichStyle(),
        text: String,
        href: String? = nil,
        config: AnchorConfig = AnchorConfig()
    ) {
        self.href = href
        self.text = text
        self.config = config
        super.init(id: id, tagName: tagName, classNames: classNames, style: style)
    }

    @discardableResult
    public override func addChild(_ element: Node) -> Self {
        if text.isEmpty {
            super.addChild(element)
        }
        return self
    }

    @discardableResult
    public override func children(_ elements: [Node]) -> Self {
        if text.isEmpty {
            super.children(elements)
        }
        return self
    }

    public override func shouldCreateRenderer() -> Bool {
        true
    }

    public override func copy() -> Any {
        let cloned = LKAnchorElement(
            id: self.id,
            tagName: self.tagName,
            classNames: self.classNames,
            /// swiftlint:disable:next force_cast
            style: self.style.copy() as! LKRichStyle,
            text: self.text,
            href: self.href
        )
        return copyTo(node: cloned)
    }
// 不需要，保留注释是为了提醒如果有必要需要override此方法。
//    override func copyTo(node: Node) -> Node {
//        return super.copyTo(node: node)
//    }

    override func createRenderer(cssEngine: CSSStyleEngine? = nil) -> RenderObject {
        if !text.isEmpty {
            return RenderText(
                text: text,
                renderStyle: mergeRenderStyle(cssEngine: cssEngine, node: self),
                ownerElement: self
            )
        }
        return super.createRenderer(cssEngine: cssEngine)
    }

    override func defaultStringAttributes() -> [NSAttributedString.Key : Any] {
        return self.config.extraAttributes
    }

    override func getDefaultString() -> NSMutableAttributedString {
        let str = href ?? text
        if !str.isEmpty {
            return attachCopyPasteStyle(with: str)
        }
        return super.getDefaultString()
    }
}
