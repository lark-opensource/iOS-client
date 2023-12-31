//
//  LKAssetBrowserActionHandler.swift
//  LarkUIKit
//
//  Created by 刘晚林 on 2017/8/11.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkActionSheet
import LarkUIKit
import LarkKeyCommandKit
import LarkSensitivityControl
import EENavigator
import RxSwift
import UniverseDesignToast
import UniverseDesignActionPanel
import Photos

public protocol LKAssetBrowserActionHandlerDelegate: AnyObject {
    func photoDenied()
    func dismissViewController(completion: (() -> Void)?)
    func canTranslate(assetKey: String) -> Bool
    func handleTranslate(asset: LKDisplayAsset)
}

open class LKAssetBrowserActionHandler {
    public internal(set) weak var delegate: LKAssetBrowserActionHandlerDelegate?

    public weak var viewController: UIViewController?

    public init() {}

    open func handleClickLoadOrigin() {}

    open func handleClickAlbum() {}

    open func handleClickTranslate() {}

    open func handleClickMoreButton(image: UIImage,
                                    asset: LKDisplayAsset,
                                    browser: LKAssetBrowserViewController,
                                    sourceView: UIView?) {}

    open func handleClickMoreButtonForVideo(asset: LKDisplayAsset,
                                            videoDisplayView: LKVideoDisplayViewProtocol,
                                            browser: LKAssetBrowserViewController,
                                            sourceView: UIView?) {}

    open func handleLongPressFor(image: UIImage, asset: LKDisplayAsset, browser: LKAssetBrowserViewController, sourceView: UIView?) {
        // TODO: ??? SourceView 丢弃了
        handleLongPressFor(image: image, asset: asset, browser: browser)
    }

    @available(*, deprecated, message: "please use the method below")
    open func handleClickPhotoEditting(image: UIImage, form browser: LKAssetBrowserViewController) {}

    open func handleClickPhotoEditting(image: UIImage, asset: LKDisplayAsset, from browser: LKAssetBrowserViewController) {}

    open func handleClickPhotoOCR(image: UIImage, asset: LKDisplayAsset, from browser: LKAssetBrowserViewController) {}

    open func handleLongPressFor(image: UIImage, asset: LKDisplayAsset, browser: LKAssetBrowserViewController) {
        if let currentPageView = browser.currentPageView {
            let actionSheet = UDActionSheet(config: .init(popSource: .init(
                sourceView: currentPageView,
                sourceRect: CGRect(origin: currentPageView.longGesture.location(in: currentPageView), size: .zero)
            )))
            actionSheet.addDefaultItem(text: BundleI18n.LarkAssetsBrowser.Lark_Legacy_SaveImage) { [weak self] in
                self?.handleSavePhoto(image: image, saveImageCompletion: nil)
            }
            actionSheet.setCancelItem(text: BundleI18n.LarkAssetsBrowser.Lark_Legacy_Cancel)
            browser.present(actionSheet, animated: true, completion: nil)
        }
    }

    open func getSaveImageKeyCommand(asset: LKDisplayAsset, relatedImage: UIImage?) -> [KeyBindingWraper] {
        return []
    }

    open func getSaveVideoKeyCommand(videoDisplayView: LKVideoDisplayViewProtocol, asset: LKDisplayAsset) -> [KeyBindingWraper] {
        return []
    }

    open func handleLongPressForVideo(asset: LKDisplayAsset,
                                      videoDisplayView: LKVideoDisplayViewProtocol,
                                      browser: LKAssetBrowserViewController,
                                      sourceView: UIView?) {
        handleLongPressForVideo(asset: asset, videoDisplayView: videoDisplayView, browser: browser)
    }

    open func handleLongPressForVideo(asset: LKDisplayAsset,
                                      videoDisplayView: LKVideoDisplayViewProtocol,
                                      browser: LKAssetBrowserViewController) {
        if let currentPageView = browser.currentPageView {
            let adapter = ActionSheetAdapter()
            let actionSheet = adapter.create(level:
                .normal(source:
                    ActionSheetAdapterSource(
                        sourceView: currentPageView,
                        sourceRect: CGRect(origin: currentPageView.longGesture.location(in: currentPageView), size: .zero),
                        arrowDirection: .unknown
                    )
                )
            )
            adapter.addItem(title: BundleI18n.LarkAssetsBrowser.Lark_Legacy_Sure) {}
            adapter.addCancelItem(title: BundleI18n.LarkAssetsBrowser.Lark_Legacy_Cancel)

            browser.present(actionSheet, animated: true, completion: nil)
        }
    }

    open func handleLongPressForSVG(
        asset: LKDisplayAsset,
        browser: LKAssetBrowserViewController,
        sourceView: UIView?
    ) {
        handleLongPressForSVG(asset: asset, browser: browser)
    }

    open func handleLongPressForSVG(asset: LKDisplayAsset, browser: LKAssetBrowserViewController) {}

    open var canHandleSaveVideoToAlbum: Bool { return true }

    /// Click save button to save current asset.
    /// - Parameters:
    ///   - asset: Current asset that is image or video type.
    ///   - relatedImage: When current asset is image type, it is the image held by UI.
    ///                   If the save button support video type in the future,
    ///                   it is nil or the cover image that is determined by then.
    open func handleSaveAsset(_ asset: LKDisplayAsset, relatedImage: UIImage?, saveImageCompletion: ((Bool) -> Void)?) {
        if let image = relatedImage {
            handleSavePhoto(image: image, saveImageCompletion: saveImageCompletion)
        }
    }

    /// 先走方法`handleSaveAssets`，在返回的结果有错误时，会先调用此方法
    /// 如果返回false，使用默认报错toast；
    /// 如果返回true，使用方法内的报错方案；
    open func saveAssetsCustomErrorHandler(results: [Swift.Result<Void, Error>], from: NavigatorFrom?) -> Bool {
        return false
    }

    /// Click save button to save current assets.
    /// - Parameters:
    ///   - assets: Current assets that is image or video type.
    ///   - relatedImage: When current asset is image type, it is the image held by UI.
    ///                   If the save button support video type in the future,
    ///                   it is nil or the cover image that is determined by then.
    open func handleSaveAssets(_ assets: [(LKDisplayAsset, UIImage?)], granted: Bool, saveImageCompletion: ((Bool) -> Void)?)
    -> Observable<[Swift.Result<Void, Error>]> {
        return .just([])
    }

    @available(*, deprecated, message: "Use `handleSaveAsset` instead.")
    open func handleSavePhoto(image: UIImage, saveImageCompletion: ((Bool) -> Void)?) {
        guard let window = viewController?.view.window else { return }
        PHPhotoLibrary.shared().performChanges {
            _ = try? AlbumEntry.creationRequestForAsset(forToken: AssetBrowserToken.creationRequestForAsset.token,
                                                        fromImage: image)
        } completionHandler: { (success, _) in
            DispatchQueue.main.async {
                if success {
                    UDToast.showSuccess(with: BundleI18n.LarkAssetsBrowser.Lark_Legacy_SavedToast, on: window)
                    saveImageCompletion?(true)
                } else {
                    saveImageCompletion?(false)
                }
            }
        }
    }

    open func handleCurrentShowedAsset(asset: LKDisplayAsset) {}

    open func handleCurrentVideoShowedAsset(asset: LKDisplayAsset, videoDisplayView: LKVideoDisplayViewProtocol) {}

    open func handlePreviousShowedAsset(previousAsset: LKDisplayAsset, currentAsset: LKDisplayAsset) {}

    open func handleNextShowedAsset(nextAsset: LKDisplayAsset, currentAsset: LKDisplayAsset) {}

    open func handleLoadMoreOld(completion: @escaping ([LKDisplayAsset], Bool) -> Void) {}

    open func handleLoadMoreNew(completion: @escaping ([LKDisplayAsset], Bool) -> Void) {}

    open func handleSaveSVG(_ asset: LKDisplayAsset) {}
}
