//
//  IconButtonPropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/2/22.
//

import Foundation
import RustPB

struct IconButtonPropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .iconButton, "type unmatched!")

        var iconButton = base?.iconButton ?? .init()
        data.previewPropertyData.forEach { key, value in
            guard let attr = Basic_V1_ComponentAttribute(rawValue: Int(key)) else { return }
            switch attr {
            case .icon: iconButton.icon = value.imageSet
            case .actionID: iconButton.actionID = value.str
            case .isDisable: iconButton.isDisable = value.b
            case .alt: iconButton.alt = value.str
            case .udIconKey: iconButton.udIcon.key = value.str
            case .udIconThemeColor: iconButton.udIcon.color = value.themeColor
            case .unicode: iconButton.udIcon.unicode = value.str
            @unknown default: return
            }
        }
        return .iconButton(iconButton)
    }
}
