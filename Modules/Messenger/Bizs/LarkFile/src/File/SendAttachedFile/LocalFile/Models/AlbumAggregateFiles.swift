//
//  AlbumAggregateFiles.swift
//  LarkFile
//
//  Created by ChalrieSu on 2018/9/20.
//

import Foundation
import Photos
import LarkMessengerInterface

struct AlbumAggregateFiles: AggregateAttachedFiles {
    private let fetchResult: PHFetchResult<PHAsset>
    private let resourceCache = NSCache<NSString, PHAssetResource>()

    init(fetchResult: PHFetchResult<PHAsset>) {
        self.fetchResult = fetchResult
    }

    var type: AttachedFileType {
        return .albumVideo
    }

    var filesCount: Int {
        return fetchResult.count
    }

    func fileAtIndex(_ index: Int) -> AttachedFile {
        return AlbumFile(asset: fetchResult.object(at: index), resourceCache: resourceCache)
    }
}
