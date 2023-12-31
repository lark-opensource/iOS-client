//
//  LKAsset.swift
//  LKBaseAssetBrowser
//
//  Created by Hayden Wang on 2022/1/25.
//

import Foundation
import UIKit
import Photos

public enum LKAssetType {
    case sync
    case async
}

public protocol LKAsset {

    var identifier: String { get }
    var resourceType: LKAssetType { get }
    var associatedPageType: LKGalleryPage.Type { get }
    func displayAsset(on assetPage: LKGalleryPage)
    func cancelAsset(on assetPage: LKGalleryPage)
}

// downloadable Asset
public protocol LKLoadableAsset: LKAsset {
    var updateProgressState: ((LKDisplayAssetState) -> Void)? { get set }
    func downloadOrigin(on assetPage: LKGalleryPage)
}

public extension LKAsset {

    var identifier: String { "" }
    var resourceType: LKAssetType { .sync }
    func cancelAsset(on assetPage: LKGalleryPage) {}
}

public struct LKLocalImageAsset: LKAsset {

    public typealias AssetPage = LKAssetBaseImagePage

    public var image: UIImage

    public var resourceType: LKAssetType { .sync }

    public var associatedPageType: LKGalleryPage.Type { LKAssetBaseImagePage.self }

    public init(image: UIImage) {
        self.image = image
    }

    public func displayAsset(on assetPage: LKGalleryPage) {
        guard let page = assetPage as? LKAssetBaseImagePage else { return }
        page.imageView.image = image
    }
}
