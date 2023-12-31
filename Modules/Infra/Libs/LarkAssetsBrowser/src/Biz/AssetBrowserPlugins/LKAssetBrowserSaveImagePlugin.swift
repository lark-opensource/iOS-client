//
//  LKAssetBrowserSaveImagePlugin.swift
//  LarkAssetsBrowser
//
//  Created by Hayden Wang on 2022/11/14.
//

import Foundation
import LarkFoundation
import LarkSensitivityControl
import UIKit
import LarkUIKit
import Photos
import UniverseDesignToast
import LarkCache

open class LKAssetBrowserSaveImagePlugin: LKAssetBrowserPlugin {

    open override var type: LKAssetPluginPosition {
        .all
    }
    
    open override var icon: UIImage? {
        Resources.new_save_photo
    }
    
    open override var title: String? {
        BundleI18n.LarkAssetsBrowser.Lark_Legacy_SaveImage
    }
    
    open override func shouldDisplayPlugin(on context: LKAssetBrowserContext) -> Bool {
        let currentPage = context.currentPage
        if let page = currentPage as? LKAssetBaseImagePage, let _ = page.imageView.image {
            return true
        } else if let page = currentPage as? LKAssetByteImageViewPage, let _ = page.imageView.image {
            return true
        }
        return false
    }
    
    open override func handleAsset(on context: LKAssetBrowserContext) {
        if let imagePage = context.currentPage as? LKAssetBaseImagePage, let image = imagePage.imageView.image {
            saveImage(image, on: context)
        } else if let imagePage = context.currentPage as? LKAssetByteImageViewPage, let image = imagePage.imageView.image {
            saveImage(image, on: context)
        }
    }
    
    private func saveImage(_ image: UIImage, on context: LKAssetBrowserContext) {
        guard let view = context.assetBrowser?.view else {
            Utils.savePhoto(image: image) { _, _ in }
            return
        }

        try? Utils.savePhoto(token: AssetBrowserToken.savePhoto.token, image: image) { success, _ in
            if success {
                UDToast.showSuccess(with: BundleI18n.LarkAssetsBrowser.Lark_Legacy_SavedToast, on: view)
            } else {
                UDToast.showFailure(with: BundleI18n.LarkAssetsBrowser.Lark_Legacy_PhotoZoomingSaveImageFail, on: view)
            }
        }
    }
}

open class LKAssetBrowserRestrictedSaveImagePlugin: LKAssetBrowserSaveImagePlugin {

    open override func handleAsset(on context: LKAssetBrowserContext) {
        if LarkCache.isCryptoEnable() {
            if let view = context.assetBrowser?.view {
                UDToast.showFailure(with: BundleI18n.LarkAssetsBrowser.Lark_Core_SecuritySettingKAToast, on: view)
            }
            return
        }
        super.handleAsset(on: context)
    }
}
