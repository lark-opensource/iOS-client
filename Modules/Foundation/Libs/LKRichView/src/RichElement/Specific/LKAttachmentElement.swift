//
//  LKAttachmentElement.swift
//  LKRichView
//
//  Created by 白言韬 on 2021/8/3.
//

import UIKit
import Foundation

/// Attachment相关配置
public struct AttachmentConfig {
    /// getDefaultString时需要额外附加的Attributes
    public let extraAttributes: [NSAttributedString.Key: Any]

    public init(_ extraAttributes: [NSAttributedString.Key: Any] = [:]) {
        self.extraAttributes = extraAttributes
    }
}

public final class LKAttachmentElement: LKRichElement {
    #if DEBUG
    public override var name: String {
        return "#attachment"
    }
    #endif

    /// Attachment相关配置
    private let config: AttachmentConfig

    public override var tag: Int8 {
        PrivateTags.attachment.rawValue
    }

    public var attachment: LKRichAttachment?

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

    public init(
        id: String = "",
        classNames: [String] = [],
        style: LKRichStyle = LKRichStyle(),
        attachment: LKRichAttachment? = nil,
        config: AttachmentConfig = AttachmentConfig()
    ) {
        self.attachment = attachment
        self.config = config
        if let attachment = attachment {
            style.verticalAlign(attachment.verticalAlign)
            if let padding = attachment.padding {
                style.padding(top: padding.top, right: padding.right, bottom: padding.bottom, left: padding.left)
            }
        }
        super.init(id: id, tagName: PrivateTags.attachment, classNames: classNames, style: style)
    }

    public override func shouldCreateRenderer() -> Bool {
        attachment != nil
    }

    public override func addChild(_ element: Node) -> Self {
        self
    }

    public override func children(_ elements: [Node]) -> Self {
        self
    }

    public override func copy() -> Any {
        let cloned = LKAttachmentElement(
            id: self.id,
            classNames: self.classNames,
            /// swiftlint:disable:next force_cast
            style: self.style.copy() as! LKRichStyle,
            attachment: self.attachment,
            config: self.config
        )
        return copyTo(node: cloned)
    }
// 不需要，保留注释是为了提醒如果有必要需要override此方法。
//    override func copyTo(node: Node) -> Node {
//        return super.copyTo(node: node)
//    }

    override func createRenderer(cssEngine: CSSStyleEngine? = nil) -> RenderObject {
        guard let attachment = attachment else {
            return RenderObject(nodeType: type, renderStyle: style.storage, ownerElement: self)
        }
        return RenderAttachment(
            nodeType: type,
            renderStyle: mergeRenderStyle(cssEngine: cssEngine, node: self),
            ownerElement: self,
            attachment: attachment
        )
    }

    override func getDefaultString() -> NSMutableAttributedString {
        assert(!defaultString.isEmpty)
        if !self.config.extraAttributes.isEmpty {
            let resultString = attachCopyPasteStyle(with: defaultString)
            resultString.addAttributes(self.config.extraAttributes, range: NSRange(location: 0, length: resultString.length))
            return resultString
        }
        return attachCopyPasteStyle(with: defaultString)
    }
}
