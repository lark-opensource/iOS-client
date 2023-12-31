//
//  OversizedTextPropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by Ping on 2023/1/7.
//

import Foundation
import RustPB

struct OversizedTextPropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .oversizedText, "type unmatched!")

        var oversizedText = base?.oversizedText ?? .init()
        let baseOversizedText = base?.oversizedText ?? .init()
        data.previewPropertyData.forEach { key, value in
            guard let attr = Basic_V1_ComponentAttribute(rawValue: Int(key)) else { return }
            switch attr {
            case .text: oversizedText.text = value.str
            case .numberOfLines: oversizedText.numberOfLines = value.i32
            case .fontSize: oversizedText.fontSize = value.i32
            case .fontWeight: oversizedText.fontWeight = .init(rawValue: Int(value.i32)) ?? baseOversizedText.fontWeight
            @unknown default: return
            }
        }
        return .oversizedText(oversizedText)
    }
}
