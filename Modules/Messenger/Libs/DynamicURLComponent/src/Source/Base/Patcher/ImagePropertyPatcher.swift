//
//  ImagePropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/2/22.
//

import Foundation
import RustPB

struct ImagePropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .image, "type unmatched!")

        var image = base?.image ?? .init()
        data.previewPropertyData.forEach { key, value in
            guard let attr = Basic_V1_ComponentAttribute(rawValue: Int(key)) else { return }
            switch attr {
            case .image: image.image = value.imageSet
            case .alt: image.alt = value.str
            case .udIconKey: image.udIcon.key = value.str
            case .imageURL: image.imageURL = value.str
            case .udIconThemeColor: image.udIcon.color = value.themeColor
            case .unicode: image.udIcon.unicode = value.str
            @unknown default: return
            }
        }
        return .image(image)
    }
}
