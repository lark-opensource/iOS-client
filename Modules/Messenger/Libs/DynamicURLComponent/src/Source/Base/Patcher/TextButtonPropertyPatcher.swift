//
//  TextButtonPropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/2/22.
//

import Foundation
import RustPB

struct TextButtonPropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .textButton, "type unmatched!")

        var textButton = base?.textButton ?? .init()
        data.previewPropertyData.forEach { key, value in
            guard let attr = Basic_V1_ComponentAttribute(rawValue: Int(key)) else { return }
            switch attr {
            case .text: textButton.text = value.str
            case .actionID: textButton.actionID = value.str
            case .isDisable: textButton.isDisable = value.b
            @unknown default: return
            }
        }
        return .textButton(textButton)
    }
}
