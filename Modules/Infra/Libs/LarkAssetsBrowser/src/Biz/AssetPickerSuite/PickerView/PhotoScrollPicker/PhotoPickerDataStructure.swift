//
//  PhotoPickerDataStructure.swift
//  LarkUIKit
//
//  Created by liuwanlin on 2017/12/11.
//  Copyright © 2017年 liuwanlin. All rights reserved.
//

import Foundation
import Photos

public enum PhotoPickerSelectDisableType {
    case cannotMix
    case maxImageCount(Int)
    case maxVideoCount(Int)
    case maxAssetsCount(Int)
}

extension PhotoPickerAssetType {
    var maxImageCount: Int {
        var maxImageCount = 0
        switch self {
        case .imageOnly(maxCount: let maxCount):
            maxImageCount = maxCount
        case .videoOnly(maxCount: _):
            break
        case .imageAndVideo(imageMaxCount: let imageCount, videoMaxCount: _):
            maxImageCount = imageCount
        case .imageOrVideo(imageMaxCount: let imageCount, videoMaxCount: _):
            maxImageCount = imageCount
        case .imageAndVideoWithTotalCount(totalCount: let totalCount):
            maxImageCount = totalCount
        }
        return maxImageCount
    }

    var maxVideoCount: Int {
        var maxVideoCount = 0
        switch self {
        case .imageOnly:
            break
        case .videoOnly(maxCount: let maxCount):
            maxVideoCount = maxCount
        case .imageAndVideo(_, videoMaxCount: let videoCount):
            maxVideoCount = videoCount
        case .imageOrVideo(_, videoMaxCount: let videoCount):
            maxVideoCount = videoCount
        case .imageAndVideoWithTotalCount(totalCount: let totalCount):
            maxVideoCount = totalCount
        }
        return maxVideoCount
    }
}

protocol PhotoScrollPickerDelegate: AnyObject {
    // 可以理解成tableview的使用形式
    func itemSelected(asset: PHAsset)
    func itemDeSelected(itemIdentifier: String)
    func selectedItemsChanged(imageItems: [PHAsset]) // 多选时会回调
    func selectReachMax(type: PhotoPickerSelectDisableType)
    func itemSelectedByPanGesture(asset: PHAsset)
    func preview(asset: PHAsset, selectedImages: [PHAsset])
    func selectedOrPreviewItemInCloud()
    func setOriginalButton(_ isEnable: Bool)
    func set(isOrigin: Bool)
    func photoScrollPickerReload(with assetResult: PHFetchResult<PHAsset>)
}

extension PhotoScrollPickerDelegate {
    func itemSelected(asset: PHAsset) {}

    func itemDeSelected(itemIdentifier: String) {}

    func selectedItemsChanged(imageItems: [PHAsset]) {}

    func selectReachMax(type: PhotoPickerSelectDisableType) {}

    func itemSelectedByPanGesture(asset: PHAsset) {}

    func preview(asset: PHAsset, selectedImages: [PHAsset]) {}

    func selectedOrPreviewItemInCloud() {}

    func photoScrollPickerReload(with assetResult: PHFetchResult<PHAsset>) {}
}
