//
//  ImageProperty+Lark.swift
//  Action
//
//  Created by 赵冬 on 2019/4/19.
//

import Foundation
import RustPB

extension RustPB.Basic_V1_RichTextElement.ImageProperty {
    public enum ImageSource {
        case unknown
        case normal
        case docIcon
    }
}

public let localDocsPrefix = "resource://client/localResouces/docs/docType/"

extension RustPB.Basic_V1_RichTextElement.ImageProperty {
    public func getImageSource() -> ImageSource {
        var imageSource: ImageSource = .normal
        if self.originKey.hasPrefix(localDocsPrefix) {
            imageSource = .docIcon
            return imageSource
        }
        return imageSource
    }
}

extension RustPB.Basic_V1_RichTextElement.ImageProperty {
    public func modifiedImageProperty(_ imageSet: ImageSet) -> ImageProperty {
        var newProp = self
        newProp.originKey = imageSet.origin.key
        newProp.middleKey = imageSet.middle.key
        newProp.thumbKey = imageSet.thumbnail.key
        newProp.middleWebp = imageSet.middleWebp
        newProp.thumbnailWebp = imageSet.thumbnailWebp
        return newProp
    }
}
