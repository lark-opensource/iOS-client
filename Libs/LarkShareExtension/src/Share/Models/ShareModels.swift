//
//  ShareModels.swift
//  ShareExtension
//
//  Created by K3 on 2018/7/24.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkExtensionCommon

private var ShareContentItemKey: Void?
extension ShareContent {
    var item: ShareItemProtocol? {
        get {
            return objc_getAssociatedObject(self, &ShareContentItemKey) as? ShareItemProtocol
        }
        set {
            objc_setAssociatedObject(self, &ShareContentItemKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// default targetType: .friend
    ///
    /// - Parameters:
    ///   - contentType:
    ///   - item:
    convenience init(contentType: ShareContentType, item: ShareItemProtocol) {
        self.init(targetType: .friend, contentType: contentType, contentData: Data())
        self.item = item
    }

    func loadItemData() {
        guard let data = item?.toJSONData() else {
            return
        }
        self.contentData = data
    }
}

private var ShareImageItemPreviewImagesKey: Void?
extension ShareImageItem {
    var previewMaps: [URL: UIImage] {
        get {
            return objc_getAssociatedObject(self, &ShareImageItemPreviewImagesKey) as? [URL: UIImage] ?? [:]
        }
        set {
            objc_setAssociatedObject(self, &ShareImageItemPreviewImagesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var isLoadDataSuccess: Bool {
        return images.filter({ previewMaps[$0] == nil }).isEmpty
    }

    convenience init(urls: [URL], previewMaps: [URL: UIImage]) {
        self.init(images: urls)
        self.previewMaps = previewMaps
    }
}
