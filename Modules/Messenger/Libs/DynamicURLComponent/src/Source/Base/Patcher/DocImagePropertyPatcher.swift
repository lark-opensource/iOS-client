//
//  DocImagePropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/2/22.
//

import Foundation
import RustPB

struct DocImagePropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .docImage, "type unmatched!")

        var docImage = base?.docImage ?? .init()
        let baseDocImage = base?.docImage ?? .init()
        data.previewPropertyData.forEach { key, value in
            guard let attr = Basic_V1_ComponentAttribute(rawValue: Int(key)) else { return }
            switch attr {
            case .docType: docImage.docType = .init(rawValue: Int(value.i32)) ?? baseDocImage.docType
            case .thumbnailURL: docImage.thumbnailURL = value.str
            case .secretURL: docImage.secretURL = value.str
            case .secretType: docImage.secretType = value.i32
            case .secretKey: docImage.secretKey = value.str
            case .secretNonce: docImage.secretNonce = value.str
            @unknown default: return
            }
        }
        return .docImage(docImage)
    }
}
