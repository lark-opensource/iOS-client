//
//  UnderLineTransformer.swift
//  LarkRichTextCore
//
//  Created by 李晨 on 2019/3/31.
//

import UIKit
import Foundation
import LarkModel
import RustPB

public final class UnderLineTransformer: RichTextTransformProtocol {

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
        return nil
    }

    public func transformToTextFromRichText() -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return nil
    }

    public func transformToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        let priority: RichTextAttrPriority = .content
        text.enumerateAttribute(.underlineStyle, in: NSRange(location: 0, length: text.length), options: []) { (style, range, _) in
            if style is NSUnderlineStyle {
                let id = InputUtil.randomId()
                var underlineProperty = RustPB.Basic_V1_RichTextElement.UnderlineProperty()
                underlineProperty.content = (text.string as NSString).substring(with: range)
                let tuple: RichTextParseHelper.RichTextAttrTuple = (RustPB.Basic_V1_RichTextElement.Tag.u, id, .u(underlineProperty), nil)
                let attr = RichTextAttr(priority: priority, tuple: tuple)
                result.append(RichTextFragmentAttr(range, [attr]))
            }
        }
        return result
    }
}
