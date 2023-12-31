//
//  LKCodeElement.swift
//  LKRichView
//
//  Created by 李勇 on 2022/6/23.
//

import Foundation
import UIKit

/// 代码块相关配置
public struct CodeBlockConfig {
    /// getDefaultString时需要额外附加的Attributes
    public let extraAttributes: [NSAttributedString.Key: Any]

    public init(_ extraAttributes: [NSAttributedString.Key: Any] = [:]) {
        self.extraAttributes = extraAttributes
    }
}

/// IM支持发送代码块：https://bytedance.feishu.cn/docx/doxcnq2t01Cq07JwccaAO9NxCQf
public final class LKCodeElement: LKBlockElement {
    #if DEBUG
    public override var name: String {
        return "#code"
    }
    #endif

    /// 代码块相关配置
    private let config: CodeBlockConfig

    /// id用于存放elementId，业务需要
    public init(id: String = "", tagName: LKRichElementTag, config: CodeBlockConfig) {
        self.config = config
        super.init(id: id, tagName: tagName)
    }

    override func createRenderer(cssEngine: CSSStyleEngine? = nil) -> RenderObject {
        // 自身style和样式表style进行合并，得到最终要展示的style
        let finalStyle = mergeRenderStyle(cssEngine: cssEngine, node: self)
        let codeBlock = RenderBlock(nodeType: .container, renderStyle: finalStyle, ownerElement: self)
        subElements.filter { $0.shouldCreateRenderer() }.forEach {
            codeBlock.appendChild($0.createRenderer(cssEngine: cssEngine))
        }
        return codeBlock
    }

    /// 使用外部传入的代码内容进行返回
    public override func getDefaultString() -> NSMutableAttributedString {
        if !self.config.extraAttributes.isEmpty {
            let resultString = attachCopyPasteStyle(with: defaultString)
            resultString.addAttributes(self.config.extraAttributes, range: NSRange(location: 0, length: resultString.length))
            return resultString
        }
        return attachCopyPasteStyle(with: defaultString)
    }
}

/// 代码行相关配置，可以控制代码行展示行为
public struct CodeLineConfig {
    /// 行号
    public let number: Int
    /// 行号字体大小
    public let fontSize: CGFloat
    /// 行号颜色
    public let color: UIColor
    /// 每行代码需要偏移多少展示行号
    public let offset: CGFloat
    /// 行号和内容的间隔
    public let space: CGFloat

    public init(_ number: Int = 0,
                _ fontSize: CGFloat = 12,
                _ color: UIColor = UIColor.black,
                _ offset: CGFloat = 0.0,
                _ space: CGFloat = 4.0) {
        self.number = number
        self.fontSize = fontSize
        self.color = color
        self.offset = offset
        self.space = space
    }
}

public final class LKCodeLineElement: LKBlockElement {
    #if DEBUG
    public override var name: String {
        return "#codeLine"
    }
    #endif

    /// 代码行相关配置
    private let config: CodeLineConfig

    public init(tagName: LKRichElementTag, config: CodeLineConfig) {
        self.config = config
        super.init(tagName: tagName)
    }

    override func createRenderer(cssEngine: CSSStyleEngine? = nil) -> RenderObject {
        let textElement = LKTextElement(text: "\(self.config.number)")
        textElement.style.fontSize(.point(self.config.fontSize))
        textElement.style.color(self.config.color)
        guard let renderText = textElement.createRenderer(cssEngine: cssEngine) as? RenderText else {
            return RenderObject(nodeType: .element, renderStyle: LKRenderRichStyle(), ownerElement: self)
        }

        // 自身style和样式表style进行合并，得到最终要展示的style
        let finalStyle = mergeRenderStyle(cssEngine: cssEngine, node: self)
        let codeLine = RenderCodeLine(nodeType: .container, renderStyle: finalStyle, ownerElement: self, lineNumberRender: renderText)
        subElements.filter { $0.shouldCreateRenderer() }.forEach {
            codeLine.appendChild($0.createRenderer(cssEngine: cssEngine))
        }

        codeLine.codeLineOffset = self.config.offset
        codeLine.codeLineSpace = self.config.space
        return codeLine
    }

    /// 控制子Element只能是LKTextElement
    @discardableResult
    public override func addChild(_ element: Node) -> Self {
        guard element is LKTextElement else {
            assertionFailure()
            return self
        }
        return super.addChild(element)
    }

    @discardableResult
    public override func children(_ elements: [Node]) -> Self {
        if elements.contains(where: { !($0 is LKTextElement) }) {
            assertionFailure()
            return self
        }
        return super.children(elements)
    }

    override func getDefaultString() -> NSMutableAttributedString {
        let defaultString = super.getDefaultString()
        defaultString.append(NSAttributedString(string: "\n"))
        return defaultString
    }
}
