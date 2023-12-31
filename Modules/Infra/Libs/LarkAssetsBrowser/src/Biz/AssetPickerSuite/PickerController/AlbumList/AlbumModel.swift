//
//  AlbumListModel.swift
//  LarkImagePicker
//
//  Created by ChalrieSu on 2018/8/30.
//  Copyright © 2018 ChalrieSu. All rights reserved.
//

import Foundation
import UIKit
import Photos

struct Album: Equatable {
    let collection: PHAssetCollection
    let fetchResult: PHFetchResult<PHAsset>
    let isReversed: Bool

    var identifier: String {
        return collection.localIdentifier
    }

    var localizedTitle: String {
        return collection.localizedTitle ?? ""
    }

    var assetsCount: Int {
        return fetchResult.count
    }

    var firstObject: PHAsset? {
        if isReversed {
            return fetchResult.lastObject
        } else {
            return fetchResult.firstObject
        }
    }

    var reversed: Album {
        return Album(collection: collection, fetchResult: fetchResult, isReversed: !isReversed)
    }

    init(collection: PHAssetCollection, fetchResult: PHFetchResult<PHAsset>, isReversed: Bool = false) {
        self.collection = collection
        self.fetchResult = fetchResult
        self.isReversed = isReversed
    }

    func asset(at index: Int) -> PHAsset {
        if isReversed {
            return safeAsset(at: assetsCount - 1 - index)
        } else {
            return safeAsset(at: index)
        }
    }

    func index(of asset: PHAsset) -> Int {
        if isReversed {
            return assetsCount - 1 - fetchResult.index(of: asset)
        } else {
            return fetchResult.index(of: asset)
        }
    }

    static func == (lhs: Album, rhs: Album) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.fetchResult === rhs.fetchResult
    }

    static var empty: Album {
        let collection = PHAssetCollection.transientAssetCollection(with: [], title: nil)
        let fetchResult = PHAsset.fetchAssets(in: collection, options: nil)
        return Album(collection: collection, fetchResult: fetchResult)
    }

    private func safeAsset(at index: Int) -> PHAsset {
        guard index >= 0, index < assetsCount else {
            assertionFailure("非法index")
            return PHAsset()
        }
        return fetchResult.object(at: index)
    }
}
