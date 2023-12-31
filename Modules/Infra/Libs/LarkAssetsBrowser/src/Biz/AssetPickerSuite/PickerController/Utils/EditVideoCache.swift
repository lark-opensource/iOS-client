//
//  EditVideoCache.swift
//  LarkAssetsBrowser
//
//  Created by 李晨 on 2022/2/28.
//

import Foundation
import Photos

public final class EditVideoCache {
    private var editVideos: [String: URL] = [:]

    public init() {}

    public func addEditVideo(_ editVideo: URL?, key: String) {
        editVideos[key] = editVideo
    }

    public func editVideo(key: String) -> URL? {
        return editVideos[key]
    }

    public func removeAll() {
        editVideos.removeAll()
    }
}

private var PHAssetEditVideoKey: Void?

public extension PHAsset {

    var editVideo: URL? {
        get { return (objc_getAssociatedObject(self, &PHAssetEditVideoKey) as? URL) }
        set(newValue) { objc_setAssociatedObject(self,
                                                 &PHAssetEditVideoKey,
                                                 newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN) }
    }
}
