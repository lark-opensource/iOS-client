//
//  ImagePickerCache.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/9/7.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import Photos

public final class EditImageCache {
    private var editImages: [String: UIImage] = [:]

    public init() {}

    public func addEditImage(_ editImage: UIImage?, key: String) {
        editImages[key] = editImage
    }

    public func editImage(key: String) -> UIImage? {
        return editImages[key]
    }

    public func removeAll() {
        editImages.removeAll()
    }
}
