//
//  LKTextElement.swift
//  LKRichView
//
//  Created by 白言韬 on 2021/8/3.
//

import Foundation

final public class LKTextElement: LKRichElement {
    #if DEBUG
    public override var name: String {
        return "#text"
    }
    #endif

    public override var type: Node.TypeEnum {
        .text
    }
    public override var tag: Int8 {
        PrivateTags.text.rawValue
    }
    override var isInline: Bool {
        true
    }
    override var isBlock: Bool {
        false
    }

    public var text: String = ""

    public init(
        id: String = "",
        classNames: [String] = [],
        style: LKRichStyle = LKRichStyle(),
        text: String
    ) {
        self.text = text
        super.init(id: id, tagName: PrivateTags.text, classNames: classNames, style: style.display(.inline))
    }

    @discardableResult
    public override func addChild(_ element: Node) -> Self {
        self
    }

    @discardableResult
    public override func children(_ elements: [Node]) -> Self {
        self
    }

    public override func shouldCreateRenderer() -> Bool {
        true
    }

    public override func copy() -> Any {
        let cloned = LKTextElement(
            id: self.id,
            classNames: self.classNames,
            // swiftlint:disable:next force_cast
            style: self.style.copy() as! LKRichStyle,
            text: self.text
        )
        return copyTo(node: cloned)
    }
// 不需要，保留注释是为了提醒如果有必要需要override此方法。
//    override func copyTo(node: Node) -> Node {
//        return super.copyTo(node: node)
//    }

    override func createRenderer(cssEngine: CSSStyleEngine? = nil) -> RenderObject {
        return RenderText(
            text: text,
            renderStyle: mergeRenderStyle(cssEngine: cssEngine, node: self),
            ownerElement: self
        )
    }

    override func getDefaultString() -> NSMutableAttributedString {
        return attachCopyPasteStyle(with: text)
    }
}
