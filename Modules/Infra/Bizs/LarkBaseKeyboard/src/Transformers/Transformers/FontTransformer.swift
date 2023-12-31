//
//  FontTransformer.swift
//  LarkRichTextCore
//
//  Created by 李晨 on 2019/3/31.
//

import UIKit
import Foundation
import LarkModel
import RustPB

public final class FontTransformer: RichTextTransformProtocol {

    public init() {}

    public func transformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: false)
    }

    public func downgradeTransformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: true)
    }

    public func transformFromRichText(attributes: [NSAttributedString.Key: Any],
                                      attachmentResult: [String: String],
                                      downgrade: Bool) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            let font = attributes[.font] as? UIFont
            var attr: NSMutableAttributedString?
            var content = ""
            switch option.element.tag {
            case .i:
                if let font = font {
                    content = option.element.property.italic.content
                    attr = NSMutableAttributedString(string: content, attributes: attributes)
                    if !downgrade {
                        attr?.addAttributes([.font: font.italic,
                                             FontStyleConfig.italicAttributedKey: FontStyleConfig.italicAttributedValue], range: NSRange(location: 0, length: attr?.length ?? 0))
                    }
                }
            case .u:
                content = option.element.property.underline.content
                attr = NSMutableAttributedString(string: content, attributes: attributes)
                if !downgrade {
                    attr?.addAttributes([.underlineStyle: FontStyleConfig.underlineStyle,
                                         FontStyleConfig.underlineAttributedKey: FontStyleConfig.underlineAttributedValue],
                                        range: NSRange(location: 0, length: attr?.length ?? 0))
                }
            case .b:
                if let font = font {
                    content = option.element.property.bold.content
                    attr = NSMutableAttributedString(string: content, attributes: attributes)
                    if !downgrade {
                        attr?.addAttributes([.font: font.medium,
                                             FontStyleConfig.boldAttributedKey: FontStyleConfig.boldAttributedValue], range: NSRange(location: 0, length: attr?.length ?? 0))
                    }
                }
            @unknown default:
                break
            }
            if let attr = attr {
                return [attr]
            }
            return []
        }
        return [(.i, process), (.u, process), (.b, process)]
    }

    /// 这里发送统一使用style的方式
    public func transformToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        return []
    }

    /// 处理 italic bold underline
    public func transformToTextFromRichText() -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            var content = ""
            switch option.element.tag {
            case .i:
                content = option.element.property.italic.content
            case .b:
                content = option.element.property.bold.content
            case .u:
                content = option.element.property.underline.content
            @unknown default:
                break
            }
             return [NSAttributedString(string: "\(content)")]
        }
        return [(.i, process), (.b, process), (.u, process)]
    }
}
