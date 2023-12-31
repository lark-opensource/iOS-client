//
//  QuoteTransformer.swift
//  LarkRichTextCore
//
//  Created by bytedance on 6/9/22.
//

import UIKit
import Foundation
import LarkModel
import RustPB

//解析quote标签
public final class QuoteTransformer: RichTextTransformProtocol {
    public init() {}

    public func transformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: false)
    }

    public func downgradeTransformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: true)
    }

    // richtext 转化 编辑显示的 属性字符串
    public func transformFromRichText(attributes: [NSAttributedString.Key: Any],
                                      attachmentResult: [String: String],
                                      downgrade: Bool) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            return option.results
        }
        return [(.quote, process)]
    }

    // 编辑显示的 属性字符串转化为 richText
    public func transformToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        return []
    }

    // richText 转化为显示使用的纯字符串
    public func transformToTextFromRichText() -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return transformFromRichText(attributes: [:], attachmentResult: [:], downgrade: false)
    }
}
