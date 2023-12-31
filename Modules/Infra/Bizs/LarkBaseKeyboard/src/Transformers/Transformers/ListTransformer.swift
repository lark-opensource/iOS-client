//
//  ListTransformer.swift
//  LarkRichTextCore
//
//  Created by bytedance on 6/7/22.
//

import UIKit
import Foundation
import LarkModel
import RustPB

//解析ol（orderList）和ul（unorderList）标签
public final class ListTransformer: RichTextTransformProtocol {

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
        //li标签
        let liProcess: RichTextElementProcess = { option -> [NSAttributedString] in
            var symbolString: String = ""
            //对于ol标签，前缀是排序的1、2、3这样的序号；
            //对于ul标签，前缀是"- "
            if let parent = option.parentElement {
                switch parent.tag {
                case .ol:
                    var start = Int(parent.property.ol.start ?? 1)
                    var index = parent.childIds.firstIndex(of: option.elementId)
                    if let index = index {
                        symbolString = "\(index + start)."
                    }
                case .ul:
                    symbolString = "- "
                @unknown default:
                    break
                }
            }
            //返回前缀标识+子element的解析结果+换行
            var result = [NSAttributedString(string: symbolString, attributes: attributes)] + option.results + [NSAttributedString(string: "\n", attributes: attributes)]
            return result
        }

        //ol和ul标签
        let parentProcess: RichTextElementProcess = { option -> [NSAttributedString] in
            return option.results
        }
        return [(.ol, parentProcess), (.ul, parentProcess), (.li, liProcess)]
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
