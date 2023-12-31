//
//  TagListPropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/2/22.
//

import Foundation
import RustPB

struct TagListPropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .tagList, "type unmatched!")

        var tagList = base?.tagList ?? .init()
        data.previewPropertyData.forEach { key, value in
            guard let attr = Basic_V1_ComponentAttribute(rawValue: Int(key)) else { return }
            switch attr {
            case .tags: tagList.tags = value.stringList.stringList
            case .mixedTags: tagList.mixedTags = value.tagList.mixedTags
            case .numberOfLines: tagList.numberOfLines = value.i32
            @unknown default: return
            }
        }
        return .tagList(tagList)
    }
}
