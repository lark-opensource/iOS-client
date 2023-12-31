//
//  ImageCache.swift
//  LarkAssetsBrowser
//
//  Created by Hayden on 2022/10/11.
//

import Foundation
import UIKit
import Photos

public final class ImageCache {
    private(set) var imageCache: [String: UIImage] = [:]

    public init() {}

    public func addCache(key: String, image: UIImage) {
        imageCache[key] = image
    }

    public func addAsset(asset: PHAsset, image: UIImage?) {
        if let image = image {
            addCache(key: asset.localIdentifier, image: image)
        }
    }

    public func removeCache(key: String, image: UIImage) {
        imageCache[key] = nil
    }

    public func removeAsset(_ asset: PHAsset) {
        imageCache[asset.localIdentifier] = nil
    }

    public func removeAll() {
        imageCache = [:]
    }

    public func imageForKey(_ key: String) -> UIImage? {
        return imageCache[key]
    }

    public func imageForAsset(_ asset: PHAsset) -> UIImage? {
        return asset.editImage ?? imageCache[asset.localIdentifier]
    }

    public func all() -> [String: UIImage] {
        return imageCache
    }
}
