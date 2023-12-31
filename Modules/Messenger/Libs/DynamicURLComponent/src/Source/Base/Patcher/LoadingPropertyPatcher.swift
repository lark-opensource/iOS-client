//
//  LoadingPropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/4/2.
//

import Foundation
import RustPB

struct LoadingPropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .loading, "type unmatched!")

        return .loading(base?.loading ?? .init())
    }
}
