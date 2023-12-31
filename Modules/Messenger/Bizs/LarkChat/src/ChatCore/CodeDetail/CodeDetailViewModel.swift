//
//  CodeDetailViewModel.swift
//  LarkChat
//
//  Created by Bytedance on 2022/11/7.
//

import UIKit
import RustPB
import Foundation
import LKRichView
import LarkMessageCore
import LarkRichTextCore
import LarkBaseKeyboard
import UniverseDesignFont
import LarkContainer

class CodeDetailViewModel: UserResolverWrapper {
    public let userResolver: UserResolver
    private let property: Basic_V1_RichTextElement.CodeBlockV2Property
    let codeElement: LKCodeElement

    init(property: Basic_V1_RichTextElement.CodeBlockV2Property, userResolver: UserResolver) {
        self.userResolver = userResolver
        self.property = property
        self.codeElement = LKCodeElement(tagName: CodeTag.code, config: CodeBlockConfig(CodeParseUtils.copyAttributes(property: property)))
        // 加padding是为了能完全展示出光标
        self.codeElement.style.padding(top: .point(10), right: .point(5), bottom: .point(10), left: .point(5))
        // 执行LKRichViewTiledManager-tiledByRect进行分片渲染，每0.5s绘制一片，避免内存OOM，还是存在空白的情况
        // self.codeElement.style.backgroundColor(UIColor.ud.bgFloat)
        // 行号宽度需要自适应
        var widthString = ""; for _ in 0..<"\(self.property.contents.count)".count { widthString += "8" }
        let maxWidthStringWidth = self.textSize(text: widthString, font: UIFont.systemFont(ofSize: 14.auto())).width

        // 遍历每一行代码，创建
        var currLineNumber: Int = 1
        property.contents.forEach { lineContent in
            let codeLine = LKCodeLineElement(tagName: CodeTag.code, config: CodeLineConfig(currLineNumber, 14.auto(), UIColor.ud.textPlaceholder, maxWidthStringWidth, 8))
            currLineNumber += 1
            // lineHeight默认继承父类，导致LineBox间有间隔（间隔根据lineHeight计算），我们主动设置取消间隔
            codeLine.style.lineHeight(.point(17.6.auto()))
            // 这里需要设置fontSize，不然也会有行间距，不是很明白为啥
            codeLine.style.fontSize(.point(14.auto()))
            // 如果是空内容，我们就伪造一个：分片渲染时，空内容行会和后续有内容行重叠渲染
            if lineContent.contents.isEmpty {
                let richStyle = LKRichStyle()
                richStyle.fontSize(.point(14.auto()))
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
                    richStyle.fontSize(.point(14.auto()))
                    // 添加该段代码
                    codeLine.addChild(LKTextElement(style: richStyle, text: content.content))
                }
            }
            self.codeElement.addChild(codeLine)
        }
    }

    private func textSize(text: String, font: UIFont) -> CGSize {
        return NSString(string: text).boundingRect(with: .zero, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil).size
    }

    func getAttributeString() -> NSAttributedString {
        return CodeTransformer.parseToAttributedString(property: self.property)
    }
}
