//
//  ChattersPreviewPropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/2/22.
//

import Foundation
import RustPB

struct ChattersPreviewPropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .chattersPreview, "type unmatched!")

        var chattersPreview = base?.chattersPreview ?? .init()
        let baseChattersPreview = base?.chattersPreview ?? .init()
        data.previewPropertyData.forEach { key, value in
            guard let attr = Basic_V1_ComponentAttribute(rawValue: Int(key)) else { return }
            switch attr {
            case .theme: chattersPreview.theme = .init(rawValue: Int(value.i32)) ?? baseChattersPreview.theme
            case .chattersCount: chattersPreview.chattersCount = value.i32
            case .chattersInfos: chattersPreview.chatterInfos = value.chatterInfos.chatterInfos
            case .maxShowCount: chattersPreview.maxShowCount = value.i32
            case .chattersMode: chattersPreview.chattersMode = .init(rawValue: Int(value.i32)) ?? baseChattersPreview.chattersMode
            case .title: chattersPreview.title = value.str
            @unknown default: return
            }
        }
        return .chattersPreview(chattersPreview)
    }
}
