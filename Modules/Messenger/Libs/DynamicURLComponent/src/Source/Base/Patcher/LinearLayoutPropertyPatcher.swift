//
//  LinearLayoutPropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/2/22.
//

import Foundation
import RustPB

struct LinearLayoutPropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .linearLayout, "type unmatched!")

        var layout = base?.linearLayout ?? .init()
        let baseLinearLayout = base?.linearLayout ?? .init()
        data.previewPropertyData.forEach { key, value in
            guard let attr = Basic_V1_ComponentAttribute(rawValue: Int(key)) else { return }
            switch attr {
            case .orientation: layout.orientation = .init(rawValue: Int(value.i32)) ?? baseLinearLayout.orientation
            case .spacing: layout.spacing = value.f
            case .wrapWidth: layout.wrapWidth = value.f
            case .padding: layout.padding = value.f
            case .mainAxisJustify: layout.mainAxisJustify = .init(rawValue: Int(value.i32)) ?? baseLinearLayout.mainAxisJustify
            case .crossAxisAlign: layout.crossAxisAlign = .init(rawValue: Int(value.i32)) ?? baseLinearLayout.crossAxisAlign
            case .sidePadding: layout.sidePadding = value.padding
            @unknown default: return
            }
        }
        return .linearLayout(layout)
    }
}
