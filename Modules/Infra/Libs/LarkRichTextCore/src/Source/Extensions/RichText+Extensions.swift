//
//  RustPB.Basic_V1_RichText+Extensions.swift
//  LarkRichTextCore
//
//  Created by liuwanlin on 2018/5/17.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import LarkModel
import RustPB
import LarkEmotion

public let defaultRichTextSummerizeOpts: [RustPB.Basic_V1_RichTextElement.Tag: StringOptionType] = [
    .docs: { option -> [String] in
        return option.results
    },
    .ul: { option -> [String] in
        return option.results
    },
    .ol: { option -> [String] in
        return option.results
    },
    .li: { option -> [String] in
        return option.results
    },
    .quote: { option -> [String] in
        return option.results
    },
    .link: { option -> [String] in
        return option.results
    },
    .textablearea: { option -> [String] in
        return option.results
    },
    .text: { option -> [String] in
        return [option.element.property.text.content]
    },
    .at: { option in
        let at = option.element
        // NOTE: 兼容老数据与新数据, 新数据 at content 前带 @ 符号
        if at.property.at.content.hasPrefix("@") {
            return [at.property.at.content]
        }

        return ["@" + at.property.at.content]
    },
    .a: { option -> [String] in
        let link = option.element
        var content = ""
        if link.property.anchor.hasTextContent {
            content = link.property.anchor.textContent
        } else {
            content = link.property.anchor.content
        }
        return [content]
    },
    .emotion: { option -> [String] in
        let emoji = option.element
        let emojiText = EmotionResouce.shared.i18nBy(key: emoji.property.emotion.key) ?? emoji.property.emotion.key
        return ["[\(emojiText)]"]
    },
    .img: { _ -> [String] in
        return [BundleI18n.LarkRichTextCore.Lark_Legacy_MessagePhoto]
    },
    .media: { _ -> [String] in
        return [BundleI18n.LarkRichTextCore.Lark_Legacy_MessagePoVideo]
    },
    .codeBlockV2: { _ -> [String] in
        return [BundleI18n.LarkRichTextCore.Lark_IM_CodeBlockQuote_Text]
    },
    .p: { option -> [String] in
        return option.results
    },
    // head降级为p
    .h1: { option -> [String] in
        return option.results
    },
    .h2: { option -> [String] in
        return option.results
    },
    .h3: { option -> [String] in
        return option.results
    },
    .h4: { option -> [String] in
        return option.results
    },
    .h5: { option -> [String] in
        return option.results
    },
    .h6: { option -> [String] in
        return option.results
    },
    .figure: { option -> [String] in
        return option.results
    },
    .mention: { option -> [String] in
        return [option.element.property.mention.content]
    },
    .myAiTool: { option -> [String] in
        let tool = option.element
        let toolName = tool.property.myAiTool.localToolName
        // 使用中
        let usingName = toolName.isEmpty ?
        BundleI18n.LarkRichTextCore.MyAI_IM_UsingExtention_Text :
        BundleI18n.LarkRichTextCore.MyAI_IM_UsingSpecificExtention_Text(toolName)
        // 已使用
        let usedName = toolName.isEmpty ?
        BundleI18n.LarkRichTextCore.MyAI_IM_UsedExtention_Text :
        BundleI18n.LarkRichTextCore.MyAI_IM_UsedSpecificExtention_Text(toolName)
        let content = tool.property.myAiTool.status == .runing ? usingName : usedName
        return [content]
    }
]

/// 部分场景不展示出某些tag而展示对应的占位符，比如：pin列表中图片展示为[图片]
let replaceTextMap: [RustPB.Basic_V1_RichTextElement.Tag: (RustPB.Basic_V1_RichTextElement) -> RustPB.Basic_V1_RichTextElement] = [
    // 图片 -> [图片]
    .img: { _ -> RustPB.Basic_V1_RichTextElement in
        var textElement = RustPB.Basic_V1_RichTextElement()
        textElement.tag = RustPB.Basic_V1_RichTextElement.Tag.text
        textElement.property.text.content = BundleI18n.LarkRichTextCore.Lark_Legacy_MessagePhoto
        return textElement
    },
    // 视频 -> [视频]
    .media: { _ -> RustPB.Basic_V1_RichTextElement in
        var textElement = RustPB.Basic_V1_RichTextElement()
        textElement.tag = RustPB.Basic_V1_RichTextElement.Tag.text
        textElement.property.text.content = BundleI18n.LarkRichTextCore.Lark_Legacy_MessagePoVideo
        return textElement
    },
    // 代码块 -> [代码块]
    .codeBlockV2: { _ -> RustPB.Basic_V1_RichTextElement in
        var textElement = RustPB.Basic_V1_RichTextElement()
        textElement.tag = RustPB.Basic_V1_RichTextElement.Tag.text
        textElement.property.text.content = BundleI18n.LarkRichTextCore.Lark_IM_CodeBlockQuote_Text
        return textElement
    }
]

extension RustPB.Basic_V1_RichText: LarkRichTextCoreExtensionCompatible {}

extension LarkRichTextCoreExtension where BaseType == RustPB.Basic_V1_RichText {
    /// 把某些tag元素替换为text元素，部分场景不展示出某些tag而展示对应的占位符，比如：pin列表中图片展示为[图片]
    public func convertText(tags: Set<RustPB.Basic_V1_RichTextElement.Tag>) -> RustPB.Basic_V1_RichText {
        var richText = self.base
        self.base.elements.forEach { (id, element) in
            guard tags.contains(element.tag) else { return }
            richText.elements[id] = replaceTextMap[element.tag]?(element) ?? element
        }
        return richText
    }

    public func summerize() -> String {
        return self.walker(options: defaultRichTextSummerizeOpts).joined()
    }

    public func walker<T>(
        options: [RustPB.Basic_V1_RichTextElement.Tag: RichTextOptionsType<T>],
        endCondition: () -> Bool = { false }
    ) -> [T] {
        return RichTextWalker.walker(
            richText: self.base,
            options: options,
            endCondition: endCondition
        )
    }
}
