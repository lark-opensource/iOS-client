//
//  HeadTransformer.swift
//  LarkBaseKeyboard
//
//  Created by 李勇 on 2023/12/12.
//

import UIKit
import Foundation
import LarkModel
import RustPB

/// Head标签到输入框降级为P，以下逻辑copy from ParagraphDocsTransformer
public final class HeadTransformer: RichTextTransformProtocol {
    public init() { }

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
            return option.results + [NSAttributedString(string: "\n", attributes: attributes)]
        }

        return [(.h1, process), (.h2, process), (.h3, process), (.h4, process), (.h5, process), (.h6, process)]
    }

    public func transformToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        return []
    }

    public func transformToTextFromRichText() -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            return option.results
        }

        return [(.h1, process), (.h2, process), (.h3, process), (.h4, process), (.h5, process), (.h6, process)]
    }
}
