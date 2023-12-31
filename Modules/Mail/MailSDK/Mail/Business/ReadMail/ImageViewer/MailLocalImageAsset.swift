//
//  MailLocalImageAsset.swift
//  MailSDK
//
//  Created by ByteDance on 2023/4/20.
//

import Foundation
import LarkAssetsBrowser
import ByteWebImage
import LarkStorage

/// 从沙盒使用 `filePath` 加载图片
final class MailLocalImageAsset: LKAsset {

    var identifier: String { url }

    var resourceType: LarkAssetsBrowser.LKAssetType { .sync }

    public var url: String

    init(url: String) {
        self.url = url
    }

    var associatedPageType: LKGalleryPage.Type {
        LKAssetByteImagePage.self
    }

    func displayAsset(on assetPage: LKGalleryPage) {
        guard let page = assetPage as? LKAssetByteImagePage else { return }
        page.imageView.image = nil
        DispatchQueue.global().async {
            if let imageData = try? Data.read(from: URL(fileURLWithPath: self.url).asAbsPath()),
               let image = try? ByteImage(imageData) {
                DispatchQueue.main.async {
                    page.imageView.image = image
                }
            }
        }
    }
}
