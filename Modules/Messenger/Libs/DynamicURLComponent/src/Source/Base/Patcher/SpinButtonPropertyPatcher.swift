//
//  SpinButtonPropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/2/22.
//

import Foundation
import RustPB

struct SpinButtonPropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .spinButton, "type unmatched!")

        var spinButton = base?.spinButton ?? .init()
        let baseSpinButton = base?.spinButton ?? .init()
        data.previewPropertyData.forEach { key, value in
            guard let attr = Basic_V1_ComponentAttribute(rawValue: Int(key)) else { return }
            switch attr {
            case .icon: spinButton.icon = value.imageSet
            case .items: spinButton.items = value.items.items
            case .selectedIndex: spinButton.selectedIndex = value.i64
            case .direction: spinButton.direction = .init(rawValue: Int(value.i32)) ?? baseSpinButton.direction
            @unknown default: return
            }
        }
        return .spinButton(spinButton)
    }
}
