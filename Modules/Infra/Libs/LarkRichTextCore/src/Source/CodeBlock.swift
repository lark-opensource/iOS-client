//
//  CodeBlock.swift
//  LarkRichTextCore
//
//  Created by liluobin on 2023/3/8.
//

import UIKit
import LKRichView
import RustPB
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignIcon

// disable-lint: magic number

/// 代码块的Tag，单独定义
public enum CodeTag: Int8, LKRichElementTag {
    case code = 100 // 代码块

    public var typeID: Int8 {
        return rawValue
    }
}

/// 代码块处理配置
public struct CodeParseConfig {
    /// 底部"x行代码"区域是否适配"字体放大需求"
    public var adjustFontScale: Bool = true
    /// 是否固定展示宽度
    public var fixedWidth: CGFloat?

    public init() {}
}

public struct CodeParseUtils {
    /// 代码块整体被复制时，携带的属性attributes
    public static func copyAttributes(property: Basic_V1_RichTextElement.CodeBlockV2Property) -> [NSAttributedString.Key: Any] {
        // 添加message.copy.code.key，以便粘贴到输入框是一个整体
        let copyCodeKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.code.key")
        // 添加一个随机数，处理两个代码块挨在一起的情况
        let randomKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "code.random.key")
        return [copyCodeKeyAttributedKey: property, randomKeyAttributedKey: "\(Date().timeIntervalSince1970)\(UInt32.random(in: 0..<100))"]
    }

    /// 会话、Pin、收藏等界面展示：有边框背景，整体选中，最多展示7行
    public static func parseToLKRichElement(property: Basic_V1_RichTextElement.CodeBlockV2Property, elementId: String, config: CodeParseConfig) -> LKCodeElement {
        func textSize(text: String, font: UIFont) -> CGSize {
            return NSString(string: text).boundingRect(with: .zero, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil).size
        }
        // 行号宽度需要自适应
        let maxWidthStringWidth = textSize(text: "8", font: UIFont.systemFont(ofSize: 12)).width
        let codeElement = LKCodeElement(id: elementId, tagName: CodeTag.code, config: CodeBlockConfig(CodeParseUtils.copyAttributes(property: property)))
        codeElement.defaultString = CodeParseUtils.parseToString(property: property)
        // 背景色、边框、圆角、padding
        codeElement.style.backgroundColor(UIColor.ud.bgBody)
        codeElement.style.border(top: BorderEdge(style: .solid, width: .point(1), color: UIColor.ud.lineBorderCard))
        codeElement.style.borderRadius(topLeft: LengthSize(width: .point(8), height: .point(8)))
        codeElement.style.padding(top: .point(8), right: .point(12), bottom: .point(8), left: .point(12))
        // 只支持整体选中、复制
        codeElement.style.isBlockSelection(true)
        // 固定展示宽度
        if let width = config.fixedWidth { codeElement.style.width(.point(width)) }

        // 代码内容
        do {
            // 最多显示多少行代码内容
            let maxLineContentNumber: Int = 7

            // 构造一个代码行容器，设置maxLinex = maxLineContentNumber，超出不展示省略号
            let codeLineBlock = LKBlockElement(tagName: CodeTag.code)
            codeLineBlock.style.lineCamp(LineCamp(maxLine: maxLineContentNumber, blockTextOverflow: ""))
            // 超出不展示省略号
            codeLineBlock.style.textOverflow(.none)
            // lineHeight默认继承父类，导致LineBox间有间隔（间隔根据lineHeight计算），我们主动设置取消间隔
            codeLineBlock.style.lineHeight(.point(15.08))
            // 这里需要设置fontSize，不然也会有行间距，不是很明白为啥
            codeLineBlock.style.fontSize(.point(12))
            codeElement.addChild(codeLineBlock)

            // 遍历每一行代码，创建
            var currLineNumber: Int = 1
            property.contents.forEach { lineContent in
                // 如果已经存了7行，那就不在计算了，因为最多展示7行
                if currLineNumber > maxLineContentNumber { return }

                let codeLine = LKCodeLineElement(tagName: CodeTag.code, config: CodeLineConfig(currLineNumber, 12, UIColor.ud.textPlaceholder, maxWidthStringWidth))
                currLineNumber += 1
                // lineHeight默认继承父类，导致LineBox间有间隔（间隔根据lineHeight计算），我们主动设置取消间隔
                codeLine.style.lineHeight(.point(15.08))
                // 这里需要设置fontSize，不然也会有行间距，不是很明白为啥
                codeLine.style.fontSize(.point(12))
                // 如果是空内容，我们就伪造一个：分片渲染时，空内容行会和后续有内容行重叠渲染
                if lineContent.contents.isEmpty {
                    let richStyle = LKRichStyle()
                    richStyle.fontSize(.point(12))
                    codeLine.addChild(LKTextElement(style: richStyle, text: " "))
                } else {
                    lineContent.contents.forEach { content in
                        // 获取代码块样式
                        let contentStyle = CodeTheme.default.styles[content.type] ?? CodeTheme.Style.default
                        var stringStyle: [String: String] = [:]
                        contentStyle.style.forEach { stringStyle[$0.key.rawValue] = $0.value.rawValue }
                        // 获取用户自己新增的富文本样式，进行merge
                        stringStyle = CodeParseUtils.mergeRichTextStyle(leftStyle: stringStyle, rightStyle: content.style)
                        let richStyle = CodeParseUtils.parseRichTextStyleToRichElementStyle(stringStyle)
                        richStyle.color(contentStyle.color)
                        richStyle.fontSize(.point(12))
                        // 添加该段代码
                        codeLine.addChild(LKTextElement(style: richStyle, text: content.content))
                    }
                }
                codeLineBlock.addChild(codeLine)
            }
        }

        // 底部的"X行代码"视图
        do {
            let textElement = LKTextElement(text: BundleI18n.LarkRichTextCore.Lark_IM_CodeBlockNum_Text(num: property.contents.count))
            textElement.style.color(UIColor.ud.textCaption)
            // 字体适配"字体放大"需求
            if config.adjustFontScale { textElement.style.fontSize(.point(12 * UniverseDesignFont.UDZoom.currentZoom.scale))
            } else { textElement.style.fontSize(.point(12)) }
            let indicatorElement = LKImgElement(img: UDIcon.rightSmallCcmOutlined.ud.colorize(color: UIColor.ud.textCaption).cgImage)
            indicatorElement.style.width(.point(16)).height(.point(16))
            let textIndicatorElement = LKTextIndicatorElement(tagName: CodeTag.code, text: textElement, img: indicatorElement)
            // 高度适配"字体放大"需求
            if config.adjustFontScale { textIndicatorElement.style.height(.point(20 * UniverseDesignFont.UDZoom.currentZoom.scale + 8))
            } else { textIndicatorElement.style.height(.point(20 + 8)) }
            // 只需要顶部的边框
            textIndicatorElement.style.border(
                top: BorderEdge(style: .solid, width: .point(1), color: UIColor.ud.lineDividerDefault),
                right: BorderEdge(style: .solid, width: .point(0), color: UIColor.ud.lineDividerDefault),
                bottom: BorderEdge(style: .solid, width: .point(0), color: UIColor.ud.lineDividerDefault),
                left: BorderEdge(style: .solid, width: .point(0), color: UIColor.ud.lineDividerDefault)
            )
            // 顶部边框距离内容间隔8
            textIndicatorElement.style.padding(top: .point(8), right: .point(0), bottom: .point(0), left: .point(0))
            // 距离上方代码间隔8
            textIndicatorElement.style.margin(top: .point(8), right: .point(0), bottom: .point(0), left: .point(0))
            codeElement.addChild(textIndicatorElement)
        }
        return codeElement
    }
    
    /// 合并两种style，场景：代码块渲染的样式 = 主题样式 + 用户自己新增的样式
    public static func mergeRichTextStyle(leftStyle: [String: String], rightStyle: [String: String]) -> [String: String] {
        // 以leftStyle为初始状态，用rightStyle进行合并
        var mergeStyle = leftStyle

        // 粗体直接覆盖
        if let value = rightStyle[TextStyleKey.fontWeight.rawValue], value == TextStyleValue.bold.rawValue {
            mergeStyle[TextStyleKey.fontWeight.rawValue] = TextStyleValue.bold.rawValue
        }
        // 斜体直接覆盖
        if let value = rightStyle[TextStyleKey.fontStyle.rawValue], value == TextStyleValue.italic.rawValue {
            mergeStyle[TextStyleKey.fontStyle.rawValue] = TextStyleValue.italic.rawValue
        }
        // 下划线/删除线进行合并
        if let value = rightStyle[TextStyleKey.textDecoration.rawValue] {
            let mergeValue = mergeStyle[TextStyleKey.textDecoration.rawValue] ?? "" + " " + value
            mergeStyle[TextStyleKey.textDecoration.rawValue] = mergeValue
        }
        return mergeStyle
    }
    
    public static func parseRichTextStyleToRichElementStyle(_ style: [String: String]) -> LKRichStyle {
        let richStyle = LKRichStyle()
        if let value = style[TextStyleKey.fontWeight.rawValue],
           value == TextStyleValue.bold.rawValue {
            if UDFontAppearance.isCustomFont {
                richStyle.fontWeight(.medium)
            } else {
                richStyle.fontWeight(.bold)
            }
        }
        if let value = style[TextStyleKey.fontStyle.rawValue],
           value == TextStyleValue.italic.rawValue {
            richStyle.fontStyle(.italic)
        }
        if let value = style[TextStyleKey.textDecoration.rawValue] {
            let isUnderline = value.contains(TextStyleValue.underline.rawValue)
            let isLineThrough = value.contains(TextStyleValue.lineThrough.rawValue)

            if isUnderline && isLineThrough {
                richStyle.textDecoration(.init(line: [.underline, .lineThrough], style: .solid))
            } else if isUnderline {
                richStyle.textDecoration(.init(line: [.underline], style: .solid))
            } else if isLineThrough {
                richStyle.textDecoration(.init(line: [.lineThrough], style: .solid))
            }
        }
        return richStyle
    }
    
    public static func parseToString(property: Basic_V1_RichTextElement.CodeBlockV2Property) -> String {
        var resultString = ""
        var currIndex = 1
        // 遍历每一行代码，创建
        property.contents.forEach { lineContent in
            // 添加该行的行号，避免复制只有一个docurl的代码块，粘贴出来转为docicon + title（URLInputHandler）
            resultString += "\(currIndex). "
            lineContent.contents.forEach { content in
                // 添加该段代码
                resultString += content.content
            }
            resultString += "\n"
            currIndex += 1
        }

        return resultString
    }
}

// enable-lint: magic number
