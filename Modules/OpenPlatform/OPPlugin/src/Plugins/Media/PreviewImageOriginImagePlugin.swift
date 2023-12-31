//
//  PreviewImageOriginImagePlugin.swift
//  OPPlugin
//
//  Created by ByteDance on 2022/11/25.
//

import Foundation
import LarkAssetsBrowser
import UniverseDesignToast
import OPFoundation
import LKCommonsLogging

final class PreviewImageOriginImagePlugin: LKAssetBrowserPlugin {
    static let logger = Logger.oplog(PreviewImageOriginImagePlugin.self, category: "OriginImagePlugin")

    var originUrl:String?
    
    override init() {
        super.init()
    }

    override var type: LKAssetPluginPosition {
        .actionSheet
    }

    override var title: String? {
        BDPI18n.full_image
    }

    override func shouldDisplayPlugin(on context: LKAssetBrowserContext) -> Bool {
        if EMAImageUtils.byteWebImageEnable {
            guard let asset = context.currentAsset as? OpenPluginPreviewImageAssetV2 else{
                return false
            }
            Self.logger.info("shouldDisplayOriginImagePluginV2 originUrl:\(originUrl),hasUseOriginUrl:\(asset.requestModel.hasUseOriginUrl),request.url:\(asset.requestModel.request.url?.absoluteString)")
            if let originUrl = asset.requestModel.originUrl, !asset.requestModel.hasUseOriginUrl, originUrl != asset.requestModel.request.url?.absoluteString {
                self.originUrl = originUrl
                return true
            }
            return false
        }else {
            guard let asset = context.currentAsset as? OpenPluginPreviewImageAsset else{
                return false
            }
            Self.logger.info("shouldDisplayOriginImagePlugin originUrl:\(originUrl),hasUseOriginUrl:\(asset.requestModel.hasUseOriginUrl),request.url:\(asset.requestModel.request.url?.absoluteString)")
            if let originUrl = asset.requestModel.originUrl, !asset.requestModel.hasUseOriginUrl, originUrl != asset.requestModel.request.url?.absoluteString {
                self.originUrl = originUrl
                return true
            }
            return false
        }
        
    }

    override func handleAsset(on context: LKAssetBrowserContext) {
        if EMAImageUtils.byteWebImageEnable {
            guard let originUrl = originUrl, let asset = context.currentAsset as? OpenPluginPreviewImageAssetV2, let currentPage = context.currentPage else{
                return
            }
            if let newUrl = URL(string: originUrl) {
                Self.logger.info("OriginImagePlugin handleAsset, replace to originUrl:\(originUrl)")
                asset.requestModel.request.url = newUrl
                asset.requestModel.hasUseOriginUrl = true
                asset.displayAsset(on: currentPage)
            }else {
                Self.logger.info("OriginImagePlugin handleAsset, invalidUrl:\(originUrl)")
            }
        }else {
            guard let originUrl = originUrl, let asset = context.currentAsset as? OpenPluginPreviewImageAsset, let currentPage = context.currentPage else{
                return
            }
            if let newUrl = URL(string: originUrl) {
                Self.logger.info("OriginImagePlugin handleAsset, replace to originUrl:\(originUrl)")
                asset.requestModel.request.url = newUrl
                asset.requestModel.hasUseOriginUrl = true
                asset.displayAsset(on: currentPage)
            }else {
                Self.logger.info("OriginImagePlugin handleAsset, invalidUrl:\(originUrl)")
            }
        }
        
    }
    
}
