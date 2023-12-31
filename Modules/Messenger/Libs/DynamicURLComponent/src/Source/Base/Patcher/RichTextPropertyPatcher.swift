//
//  RichTextPropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/2/22.
//

import Foundation
import RustPB

struct RichTextPropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .richtext, "type unmatched!")
        var richText = base?.richText ?? .init()
        if data.hasRichText {
            richText.richtext = data.richText
        } else if let baseRichText = base?.richText {
            richText.richtext = baseRichText.richtext
        }
        return .richtext(richText)
    }
}
