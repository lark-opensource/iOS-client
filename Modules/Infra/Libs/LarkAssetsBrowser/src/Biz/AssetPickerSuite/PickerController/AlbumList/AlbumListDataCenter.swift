//
//  AlbumListDataCenter.swift
//  LarkImagePicker
//
//  Created by ChalrieSu on 2018/8/31.
//  Copyright © 2018 ChalrieSu. All rights reserved.
//

import Foundation
import LarkSensitivityControl
import UIKit
import Photos

extension PHFetchResult {
    @objc var isEmpty: Bool {
        // swiftlint:disable empty_count
        return self.count == 0
        // swiftlint:enable empty_count
    }
}

struct FetchResultHolder {
    static var results: [PHFetchResult<PHAssetCollection>] = []
    static func save(_ resultList: [PHFetchResult<PHAssetCollection>]) {
        results.removeAll()
        results.append(contentsOf: resultList)
    }
    static func removeAll() {
        results.removeAll()
    }
}

final class AlbumListDataCenter {
    private let assetType: ImagePickerAssetType
    private let allPhotos: PHFetchResult<PHAssetCollection>
    private let smartAlbums: PHFetchResult<PHAssetCollection>
    private let userAlbums: PHFetchResult<PHAssetCollection>

    /// Function may take a while to return ( due to fetchAssetCollections),  please avoid to call on main thread
    init(assetType: ImagePickerAssetType) {
        self.assetType = assetType

        do {
            self.allPhotos = try AlbumEntry.fetchAssetCollections(forToken: AssetBrowserToken.fetchAssetCollections.token,
                                                                  withType: .smartAlbum,
                                                                  subtype: .smartAlbumUserLibrary,
                                                                  options: nil)
        } catch {
            self.allPhotos = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                     subtype: .smartAlbumUserLibrary,
                                                                     options: nil)
        }

        do {
            self.smartAlbums = try AlbumEntry.fetchAssetCollections(forToken: AssetBrowserToken.fetchAssetCollections.token,
                                                                    withType: .smartAlbum,
                                                                    subtype: .any,
                                                                    options: nil)
        } catch {
            self.smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                       subtype: .any,
                                                                       options: nil)
        }

        do {
            self.userAlbums = try AlbumEntry.fetchAssetCollections(forToken: AssetBrowserToken.fetchAssetCollections.token,
                                                                   withType: .album,
                                                                   subtype: .any,
                                                                   options: nil)
        } catch {
            self.userAlbums = PHAssetCollection.fetchAssetCollections(with: .album,
                                                                      subtype: .any,
                                                                      options: nil)
        }
        FetchResultHolder.save([allPhotos, smartAlbums, userAlbums])
    }

    deinit {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            FetchResultHolder.removeAll()
        }
    }

    private func predicate() -> NSPredicate {
        let maker: (PHAssetMediaType) -> NSPredicate = {
            NSPredicate(format: "mediaType == %d", $0.rawValue)
        }
        switch assetType {
        case .imageOnly: return maker(.image)
        case .videoOnly: return maker(.video)
        case .imageOrVideo, .imageAndVideo, .imageAndVideoWithTotalCount:
            return NSCompoundPredicate(orPredicateWithSubpredicates: [maker(.image), maker(.video)])
        }
    }

    lazy var defaultAlbum: Album? = {
        if let collection = allPhotos.firstObject {
            let options = PHFetchOptions()
            options.predicate = predicate()
            let fetchResult = PHAsset.fetchAssets(in: collection, options: options)
            return Album(collection: collection, fetchResult: fetchResult)
        }
        return nil
    }()

    private let lock = NSLock()

    /// Function may take a while to return (due to fetchAssetCollections),  please avoid to call on main thread
    lazy var allAlbums: [Album] = {
        lock.lock()
        defer { lock.unlock() }

        var albums: [Album] = []

        // 默认相册（所有照片）
        let defaultIdentifier = defaultAlbum?.identifier ?? ""
        defaultAlbum.flatMap { albums.append($0) }

        let options = PHFetchOptions()
        options.predicate = predicate()
        [smartAlbums, userAlbums].forEach { (album) in
            album.enumerateObjects { (collection, _, _) in
                guard collection.localIdentifier != defaultIdentifier else { return }
                let fetchResult = PHAsset.fetchAssets(in: collection, options: options)
                if !fetchResult.isEmpty {
                    albums.append(Album(collection: collection, fetchResult: fetchResult))
                }
            }
        }
        return albums
    }()
}
