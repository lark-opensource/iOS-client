//
//  CodeTransformer.swift
//  LarkRichTextCore
//
//  Created by Bytedance on 2022/11/10.
//

import UIKit
import RustPB
import Foundation
import LKRichView
import EditTextView
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignIcon
import LarkRichTextCore

/// 输入框里的CustomTextAttachment需要提供previewImage
class LKRichAttachmentView: LKRichView, AttachmentPreviewableView {
    /// 缓存一份，UIGraphicsImageRenderer构造失败时使用
    private var cachePreviewImage: UIImage?

    public lazy var previewImage: () -> UIImage? = { [weak self] in
        guard let `self` = self else { return nil }
        // 调试发现，此时LKRichView已经执行过display/没执行会主动触发display执行；所以可以用UIGraphicsImageRenderer构造一个UIImage
        // 这里的render耗时，用iPhoneX测试是0.001s级别，不会有耗时问题
        let rendererImage = UIGraphicsImageRenderer(bounds: self.bounds).image { context in
            self.layer.render(in: context.cgContext)
        }
        if rendererImage.cgImage != nil {
            self.cachePreviewImage = rendererImage
            return rendererImage
        }

        return self.cachePreviewImage
    }
}

public final class CodeTransformer: RichTextTransformProtocol {

    /// 输入框标识，输入框中复制/剪切使用
    public static let editCodeKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "edit.code.json")

    // MARK: - init
    public init() {}

    // MARK: - private
    private static func attachCopyPasteStyle(with text: String, style: [String: String]) -> NSMutableAttributedString {
        var attributes: [NSAttributedString.Key: Any] = [:]
        if let value = style[TextStyleKey.fontWeight.rawValue], value == TextStyleValue.bold.rawValue {
            attributes[NSAttributedString.Key(rawValue: "bold")] = "bold"
        }
        if let value = style[TextStyleKey.fontStyle.rawValue], value == TextStyleValue.italic.rawValue {
            attributes[NSAttributedString.Key(rawValue: "italic")] = "italic"
        }
        if let value = style[TextStyleKey.textDecoration.rawValue] {
            if value.contains(TextStyleValue.lineThrough.rawValue) {
                attributes[NSAttributedString.Key(rawValue: "strikethrough")] = NSNumber(value: NSUnderlineStyle.single.rawValue)
            }
            if value.contains(TextStyleValue.underline.rawValue) {
                attributes[NSAttributedString.Key(rawValue: "underline")] = NSNumber(value: NSUnderlineStyle.single.rawValue)
            }
        }
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
    /// 会话输入框中使用：有边框背景，整体选中，最多展示7行，不适配"字体放大需求"
    private static func parseToTextAttachment(property: Basic_V1_RichTextElement.CodeBlockV2Property) -> LKCodeElement {
        func textSize(text: String, font: UIFont) -> CGSize {
            return NSString(string: text).boundingRect(with: .zero, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil).size
        }
        // 行号宽度需要自适应
        let maxWidthStringWidth = textSize(text: "8", font: UIFont.systemFont(ofSize: 6)).width
        let codeElement = LKCodeElement(id: "", tagName: CodeTag.code, config: CodeBlockConfig(CodeParseUtils.copyAttributes(property: property)))
        // 背景色、边框、圆角、padding
        codeElement.style.backgroundColor(UIColor.ud.bgBody)
        // 暗色模式下不能有透明度：LKRichAttachmentView中UIGraphicsImageRenderer得到的背景色/边框颜色可能和LKRichView的不一致，会导致暗色模式下边框透出亮色的颜色，看着就是白色的边框
        codeElement.style.border(top: BorderEdge(style: .solid, width: .point(0.5), color: UIColor.ud.rgb(0xDEE0E3) & UIColor.ud.rgb(0x444444)))
        codeElement.style.borderRadius(topLeft: LengthSize(width: .point(4), height: .point(4)))
        codeElement.style.padding(top: .point(4), right: .point(6), bottom: .point(4), left: .point(6))

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
            codeLineBlock.style.lineHeight(.point(7.54))
            // 这里需要设置fontSize，不然也会有行间距，不是很明白为啥
            codeLineBlock.style.fontSize(.point(6))
            codeElement.addChild(codeLineBlock)

            // 遍历每一行代码，创建
            var currLineNumber: Int = 1
            property.contents.forEach { lineContent in
                // 如果已经存了7行，那就不在计算了，因为最多展示7行
                if currLineNumber > maxLineContentNumber { return }

                let codeLine = LKCodeLineElement(tagName: CodeTag.code, config: CodeLineConfig(currLineNumber, 6, UIColor.ud.textPlaceholder, maxWidthStringWidth, 2))
                currLineNumber += 1
                // lineHeight默认继承父类，导致LineBox间有间隔（间隔根据lineHeight计算），我们主动设置取消间隔
                codeLine.style.lineHeight(.point(7.54))
                // 这里需要设置fontSize，不然也会有行间距，不是很明白为啥
                codeLine.style.fontSize(.point(6))
                // 如果是空内容，我们就伪造一个：分片渲染时，空内容行会和后续有内容行重叠渲染
                if lineContent.contents.isEmpty {
                    let richStyle = LKRichStyle()
                    richStyle.fontSize(.point(6))
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
                        richStyle.fontSize(.point(6))
                        // 添加该段代码
                        codeLine.addChild(LKTextElement(style: richStyle, text: content.content))
                    }
                }
                codeLineBlock.addChild(codeLine)
            }
        }

        // 底部的"X行代码"视图
        do {
            let textElement = LKTextElement(text: BundleI18n.LarkBaseKeyboard.Lark_IM_CodeBlockNum_Text(num: property.contents.count))
            textElement.style.color(UIColor.ud.textCaption)
            textElement.style.fontSize(.point(6))
            let indicatorElement = LKImgElement(img: UDIcon.rightSmallCcmOutlined.ud.colorize(color: UIColor.ud.textCaption).cgImage)
            indicatorElement.style.width(.point(8)).height(.point(8))
            let textIndicatorElement = LKTextIndicatorElement(tagName: CodeTag.code, text: textElement, img: indicatorElement)
            textIndicatorElement.style.height(.point(10 + 4))
            // 只需要顶部的边框
            textIndicatorElement.style.border(
                top: BorderEdge(style: .solid, width: .point(0.5), color: UIColor.ud.lineDividerDefault),
                right: BorderEdge(style: .solid, width: .point(0), color: UIColor.ud.lineDividerDefault),
                bottom: BorderEdge(style: .solid, width: .point(0), color: UIColor.ud.lineDividerDefault),
                left: BorderEdge(style: .solid, width: .point(0), color: UIColor.ud.lineDividerDefault)
            )
            // 顶部边框距离内容间隔
            textIndicatorElement.style.padding(top: .point(4), right: .point(0), bottom: .point(0), left: .point(0))
            // 距离上方代码间隔
            textIndicatorElement.style.margin(top: .point(4), right: .point(0), bottom: .point(0), left: .point(0))
            codeElement.addChild(textIndicatorElement)
        }
        return codeElement
    }

    public func transformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: false)
    }

    public func downgradeTransformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: true)
    }

    // MARK: - RichTextTransformProtocol
    /// RichText转成NSAttributedString，场景：草稿恢复、重新编辑、二次编辑等，转换完后直接进输入框，进剪贴板不使用此转换方法
    /// 1. NSAttributedString中替换所有代码内容为CustomTextAttachment，以便展示成一个整体
    public func transformFromRichText(attributes: [NSAttributedString.Key: Any],
                                      attachmentResult: [String: String],
                                      downgrade: Bool) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            if downgrade {
                let attr = NSMutableAttributedString(string: CodeParseUtils.parseToString(property: option.element.property.codeBlockV2))
                attr.addAttributes(attributes, range: NSRange(location: 0, length: attr.length))
                return [attr]
            } else {
                return [CodeTransformer.transformPropertyToTextAttachment(option.element.property.codeBlockV2)]
            }
        }
        return [(.codeBlockV2, process)]
    }
    ///  NSAttributedString转化为richText，发富文本消息、存草稿等
    public func transformToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        text.enumerateAttribute(Self.editCodeKey, in: NSRange(location: 0, length: text.length), options: [.longestEffectiveRangeNotRequired]) { (value, range, _) in
            if let property = value as? Basic_V1_RichTextElement.CodeBlockV2Property {
                let codeTuple: RichTextParseHelper.RichTextAttrTuple = (Basic_V1_RichTextElement.Tag.codeBlockV2, InputUtil.randomId(), .codeBlockV2(property), nil)
                // 添加一个Figure，让代码块能单独一行展示，逻辑copy ImageTransformer
                let pAttr = RichTextAttr(priority: .high, tuple: (Basic_V1_RichTextElement.Tag.p, InputUtil.randomId(), .p(Basic_V1_RichTextElement.ParagraphProperty()), nil))
                result.append(RichTextFragmentAttr(range, [pAttr, RichTextAttr(priority: .content, tuple: codeTuple)]))
            }
        }
        return result
    }
    /// richText 转化为显示使用的纯字符串
    public func transformToTextFromRichText() -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            return [NSAttributedString(string: BundleI18n.LarkBaseKeyboard.Lark_IM_CodeBlockQuote_Text)]
        }
        return [(.codeBlockV2, process)]
    }

    // MARK: - 工具方法
    /// 把属性字符串中的CustomTextAttachment替换为代码内容
    public static func retransformTextAttachmentToString(_ text: NSAttributedString) -> NSAttributedString {
        let resultAttributedString = NSMutableAttributedString(attributedString: text)

        // 设置longestEffectiveRangeNotRequired，连续两个的代码块也能被分开
        text.enumerateAttribute(Self.editCodeKey, in: NSRange(location: 0, length: text.length), options: [.reverse, .longestEffectiveRangeNotRequired]) { value, range, _ in
            guard let property = value as? Basic_V1_RichTextElement.CodeBlockV2Property else { return }

            let codeAttributedString = NSMutableAttributedString(string: CodeParseUtils.parseToString(property: property))
            let copyCodeKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.code.key")
            codeAttributedString.addAttributes([copyCodeKeyAttributedKey: property], range: NSRange(location: 0, length: codeAttributedString.length))
            // 添加一个随机数，处理两个代码块挨在一起的情况
            let randomKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "code.random.key")
            codeAttributedString.addAttributes([randomKeyAttributedKey: "\(Date().timeIntervalSince1970)\(UInt32.random(in: 0..<100))"], range: NSRange(location: 0, length: codeAttributedString.length))

            resultAttributedString.replaceCharacters(in: range, with: codeAttributedString)
        }

        return resultAttributedString
    }

    public static func transformPropertyToTextAttachment(_ property: Basic_V1_RichTextElement.CodeBlockV2Property) -> NSAttributedString {
        // 设置代码块的唯一标识，输入框中进行复制/剪切时候有用
        var attributes: [NSAttributedString.Key: Any] = [:]
        let randomKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "code.random.key")
        attributes[randomKeyAttributedKey] = "\(Date().timeIntervalSince1970)\(UInt32.random(in: 0..<100))"
        attributes[Self.editCodeKey] = property
        // 展示成一个整体
        let core = LKRichViewCore()
        core.load(renderer: core.createRenderer(CodeTransformer.parseToTextAttachment(property: property)))
        var contentSize = core.layout(CGSize(width: 130, height: CGFloat.greatestFiniteMagnitude)) ?? .zero
        // 宽度、高度必须为整数，不然LKRichAttachmentView中UIGraphicsImageRenderer得到的image.size和bounds.size不一样
        contentSize.height = ceil(contentSize.height)
        let richView = LKRichAttachmentView(frame: CGRect(origin: .zero, size: contentSize), options: ConfigOptions([.debug(false)]))
        richView.setRichViewCore(core)
        let attachment = CustomTextAttachment(customView: richView, bounds: CGRect(origin: .zero, size: contentSize))
        let attachmentString = NSMutableAttributedString(attachment: attachment)
        attachmentString.addAttributes(attributes, range: NSRange(location: 0, length: 1))
        return attachmentString
    }

    public static func parseToAttributedString(property: Basic_V1_RichTextElement.CodeBlockV2Property) -> NSMutableAttributedString {
        let resultString = NSMutableAttributedString()
        // 遍历每一行代码，创建
        property.contents.forEach { lineContent in
            let codeLineString = NSMutableAttributedString()
            lineContent.contents.forEach { content in
                // 获取代码块样式
                let contentStyle = CodeTheme.default.styles[content.type] ?? CodeTheme.Style.default
                var stringStyle: [String: String] = [:]
                contentStyle.style.forEach { stringStyle[$0.key.rawValue] = $0.value.rawValue }
                // 获取用户自己新增的富文本样式，进行merge
                stringStyle = CodeParseUtils.mergeRichTextStyle(leftStyle: stringStyle, rightStyle: content.style)
                // 添加该段代码
                codeLineString.append(CodeTransformer.attachCopyPasteStyle(with: content.content, style: stringStyle))
            }
            resultString.append(codeLineString)
            resultString.append(NSAttributedString(string: "\n"))
        }

        return resultString
    }
}
