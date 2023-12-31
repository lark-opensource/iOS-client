//
//  ButtonPropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/2/22.
//

import Foundation
import RustPB

struct ButtonPropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .button, "type unmatched!")

        var button = base?.button ?? .init()
        let baseButton = base?.button ?? .init()
        data.previewPropertyData.forEach { key, value in
            guard let attr = Basic_V1_ComponentAttribute(rawValue: Int(key)) else { return }
            switch attr {
            case .icon: button.icon = value.imageSet
            case .text: button.text = value.str
            case .direction: button.direction = .init(rawValue: Int(value.i32)) ?? baseButton.direction
            case .actionID: button.actionID = value.str
            case .isDisable: button.isDisable = value.b
            case .udIconKey: button.udIcon.key = value.str
            case .udIconThemeColor: button.udIcon.color = value.themeColor
            case .unicode: button.udIcon.unicode = value.str
            @unknown default: return
            }
        }
        return .button(button)
    }
}
