//
//  LKImgElement.swift
//  LKRichView
//
//  Created by 白言韬 on 2021/8/3.
//

import UIKit
import Foundation

/// Attachment相关配置
public struct ImgConfig {
    /// getDefaultString时需要额外附加的Attributes
    public let extraAttributes: [NSAttributedString.Key: Any]

    public init(_ extraAttributes: [NSAttributedString.Key: Any] = [:]) {
        self.extraAttributes = extraAttributes
    }
}

public final class LKImgElement: LKRichElement {
    #if DEBUG
    public override var name: String {
        return "#img"
    }
    #endif

    /// Attachment相关配置
    private let config: ImgConfig

    public override var type: Node.TypeEnum {
        .canvas
    }
    public override var tag: Int8 {
        PrivateTags.img.rawValue
    }
    override var isInline: Bool {
        true
    }
    override var isBlock: Bool {
        true
    }

    public var imgData: CGImage?

    public override var defaultStyleProperties: StyleProperties {
        StyleProperties([])
    }

    public init(
        id: String = "",
        classNames: [String] = [],
        style: LKRichStyle = LKRichStyle(),
        img: CGImage? = nil,
        config: ImgConfig = ImgConfig()
    ) {
        imgData = img
        self.config = config
        super.init(id: id, tagName: PrivateTags.img, classNames: classNames, style: style.display(.inlineBlock))
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
        let cloned = LKImgElement(
            id: self.id,
            classNames: self.classNames,
            /// swiftlint:disable:next force_cast
            style: self.style.copy() as! LKRichStyle,
            img: self.imgData?.copy(),
            config: self.config
        )
        return copyTo(node: cloned)
    }
// 不需要，保留注释是为了提醒如果有必要需要override此方法。
//    override func copyTo(node: Node) -> Node {
//        return super.copyTo(node: node)
//    }

    override func createRenderer(cssEngine: CSSStyleEngine? = nil) -> RenderObject {
        return RenderImg(
            nodeType: type,
            renderStyle: mergeRenderStyle(cssEngine: cssEngine, node: self),
            ownerElement: self,
            image: imgData
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
