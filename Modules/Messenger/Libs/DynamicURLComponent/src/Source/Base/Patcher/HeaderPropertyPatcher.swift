//
//  HeaderPropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/2/22.
//

import Foundation
import RustPB

struct HeaderPropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .header, "type unmatched!")

        var header = base?.header ?? .init()
        let baseHeader = base?.header ?? .init()
        data.previewPropertyData.forEach { key, value in
            guard let attr = Basic_V1_ComponentAttribute(rawValue: Int(key)) else { return }
            switch attr {
            case .icon: header.iconKey = value.imageSet
            case .title: header.title = value.str
            case .larkTag: header.larkTag = .init(rawValue: Int(value.i32)) ?? baseHeader.larkTag
            case .childComponentID: header.childComponentID = value.str
            case .showCopyLinkBtn: header.isNeedCopyLink = value.b
            case .showCloseBtn: header.isNeedClose = value.b
            case .theme: header.theme = .init(rawValue: Int(value.i32)) ?? baseHeader.theme
            case .type: header.type = .init(rawValue: Int(value.i32)) ?? baseHeader.type
            case .tagColor: header.tagColor = value.themeColor
            case .tagTextColor: header.tagTextColor = value.themeColor
            case .headerTag: header.headerTag = value.str
            case .faviconURL: header.faviconURL = value.str
            case .iconColor: header.iconColor = value.themeColor
            case .udIconKey: header.udIcon.key = value.str
            case .udIconThemeColor: header.udIcon.color = value.themeColor
            case .unicode: header.udIcon.unicode = value.str
            case .numberOfLines: header.numberOfLines = value.i32
            @unknown default: return
            }
        }
        return .header(header)
    }
}
