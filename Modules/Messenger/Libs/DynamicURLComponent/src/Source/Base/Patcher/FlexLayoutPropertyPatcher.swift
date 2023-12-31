//
//  FlexLayoutPropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by Ping on 2023/8/8.
//

import RustPB

struct FlexLayoutPropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .flexLayout, "type unmatched!")

        var layout = base?.flexLayout ?? .init()
        let baseFlexLayout = base?.flexLayout ?? .init()
        data.previewPropertyData.forEach { key, value in
            guard let attr = Basic_V1_ComponentAttribute(rawValue: Int(key)) else { return }
            switch attr {
            case .orientation: layout.orientation = .init(rawValue: Int(value.i32)) ?? baseFlexLayout.orientation
            case .flexWrap: layout.flexWrap = .init(rawValue: Int(value.i32)) ?? baseFlexLayout.flexWrap
            case .mainAxisSpacing: layout.mainAxisSpacing = value.f
            case .crossAxisSpacing: layout.crossAxisSpacing = value.f
            case .padding: layout.padding = value.padding
            case .mainAxisJustify: layout.mainAxisJustify = .init(rawValue: Int(value.i32)) ?? baseFlexLayout.mainAxisJustify
            case .crossAxisAlign: layout.crossAxisAlign = .init(rawValue: Int(value.i32)) ?? baseFlexLayout.crossAxisAlign
            case .forceUseCompactMode: layout.forceUseCompactMode = value.b
            @unknown default: return
            }
        }
        return .flexLayout(layout)
    }
}
