//
//  PreviewImageAsset.swift
//  OPPlugin
//
//  Created by ByteDance on 2022/11/22.
//

import Foundation
import LarkAssetsBrowser
import Kingfisher

final class OpenPluginPreviewImageAsset: LKAsset {

    public var requestModel: PreviewImageRequestModel
    
    public var resourceType: LKAssetType { .sync }
    
    public var associatedPageType: LKGalleryPage.Type { LKAssetBaseImagePage.self }
    
    public init(requestModel: PreviewImageRequestModel) {
        self.requestModel = requestModel
    }
    
    // LKAssetBrowser 在合适的时机（如页面即将展示时）调用该方法，将数据展示到页面上。
    public func displayAsset(on assetPage: LKGalleryPage) {
        guard let page = assetPage as? LKAssetBaseImagePage else { return }
        guard let url = requestModel.request.url else {
            return
        }
        let prevImage = page.imageView.image
        page.assetIdentifier = url.absoluteString
        page.showLoading()
        page.imageView.kf.cancelDownloadTask()
        page.imageView.ema_setImage(request: requestModel.request) {[weak page] (image, url, fromCache, opError) in
            page?.hideLoading()
        }
    }
}

//支持gif
final class OpenPluginPreviewImageAssetV2: LKAsset {

    var requestModel: PreviewImageRequestModel
    
    var resourceType: LKAssetType { .sync }
    
    var associatedPageType: LKGalleryPage.Type { LKAssetByteImageViewPage.self }
    
    init(requestModel: PreviewImageRequestModel) {
        self.requestModel = requestModel
    }
    
    // LKAssetBrowser 在合适的时机（如页面即将展示时）调用该方法，将数据展示到页面上。
    func displayAsset(on assetPage: LKGalleryPage) {
        guard let page = assetPage as? LKAssetByteImageViewPage else { return }
        guard let url = requestModel.request.url else {
            return
        }
        let prevImage = page.imageView.image
        page.assetIdentifier = url.absoluteString
        page.showLoading()
        page.imageView.kf.cancelDownloadTask()
        page.imageView.ema_setImageV2(request: requestModel.request) { [weak page] _, _, _, _ in
            page?.hideLoading()
        }
        
    }
}
