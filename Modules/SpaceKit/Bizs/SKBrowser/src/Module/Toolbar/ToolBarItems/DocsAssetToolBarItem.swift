//
//  DocsImageToolBarItem.swift
//  SpaceKit
//
//  Created by Webster on 2019/1/10.
//

import Foundation
import LarkUIKit
import Photos
import Kingfisher
import SKCommon
import SKUIKit
import LarkAssetsBrowser
import ByteWebImage
import EENavigator
import SpaceInterface
import LarkSensitivityControl
import SKFoundation
import SKInfra

/// docs tool bar item: insert image
class DocsAssetToolBarItem: DocsBaseToolBarItem {

    /// image picker controller
    var imagePickerView: DocsImagePickerToolView?
    /// js callback name belong to front end
    static var pickImageJsName: String?
    override class var restoreTag: String { return "AssetToolBar" }
    override class var restoreScript: DocsJSCallBack {
        return DocsJSCallBack.cancelFromImageSelector
    }

    /// override item type
    ///
    /// - Returns: panel type
    override func type() -> DocsToolBar.ItemType {
            return .panel
    }

    /// lazy making panelView, if view is existed just refresh attached property
    ///
    /// - Returns: reused panelview
    override func panelView() -> UIView? {
        if imagePickerView == nil {
            let width = SKDisplay.activeWindowBounds.width
            let defaultRect = CGRect(x: 0, y: 0, width: width, height: 200)
            imagePickerView = DocsImagePickerToolView(frame: defaultRect, fileType: nil, curWindow: EditorManager.shared.currentEditor?.window)
        }
        imagePickerView?.suiteView?.delegate = self
        imagePickerView?.suiteView?.onPresentBlock = { [weak self] _ in
            guard let `self` = self else { return }
            self.delegate?.requestAddRestoreTag(item: self, tag: DocsAssetToolBarItem.restoreTag)
        }
        imagePickerView?.suiteView?.finishSelectBlock = { [weak self] _, _ in
            guard let `self` = self else { return }
            self.delegate?.requestAddRestoreTag(item: self, tag: nil)
        }
        return imagePickerView
    }

    /// transfer current panel view to new toolbar item, avoid recreating all the time
    ///
    /// - Parameter item: the item who will owner the old panel view
    override func transferPanelView(to item: DocsBaseToolBarItem) {
        if let toItem = item as? DocsAssetToolBarItem,
            let fromView = self.panelView() as? DocsImagePickerToolView {
            weak var weakToItem = toItem
            toItem.imagePickerView = fromView
            fromView.suiteView?.onPresentBlock = { _ in
                guard let strongToItem = weakToItem else { return }
                strongToItem.delegate?.requestAddRestoreTag(item: self, tag: DocsAssetToolBarItem.restoreTag)
            }
            fromView.suiteView?.finishSelectBlock = { _, _ in
                guard let strongToItem = weakToItem else { return }
                strongToItem.delegate?.requestAddRestoreTag(item: strongToItem, tag: nil)
            }
            fromView.suiteView?.delegate = toItem

        }
    }

}

// MARK: - image picker controller delegate callback etc..
extension DocsAssetToolBarItem: AssetPickerSuiteViewDelegate {

    /// user has selected some photo from the album
    ///
    /// - Parameters:
    ///   - suiteView: image picker controller
    ///   - result: photo assest result
    func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didFinishSelect result: AssetPickerSuiteSelectResult) {
        var images: [UIImage] = [UIImage]()
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        let assets = result.selectedAssets

        for asset in assets {
            do {
                if #available(iOS 13.0, *) {
                    _ = try AlbumEntry.requestImageDataAndOrientation(forToken: Token(PSDATokens.DocX.doc_insert_image_click_upload),
                                                                      manager: PHImageManager.default(),
                                                                      forAsset: asset,
                                                                      options: options) {(data, _ ,_, _) in
                        guard let data = data else {
                            return
                        }
                        if let image = asset.editImage ?? DefaultImageProcessor.default.process(item: .data(data), options: [])?.lu.fixOrientation() {
                            images.append(image)
                        }
                    }
                } else {
                    _ = try AlbumEntry.requestImageData(forToken: Token(PSDATokens.DocX.doc_insert_image_click_upload),
                                                        manager: PHImageManager.default(),
                                                        forAsset: asset,
                                                        options: options) {(data, _ ,_, _) in
                        guard let data = data else {
                            return
                        }
                        if let image = asset.editImage ?? DefaultImageProcessor.default.process(item: .data(data), options: [])?.lu.fixOrientation() {
                            images.append(image)
                        }
                    }
                }
            } catch {
                DocsLogger.error("AlbumEntry requestImageDataAndOrientation error")
            }
        }
        self.jsInsertImage(images: images, isOriginal: result.isOriginal)
    }

    /// user has take photo throught image picker controller
    ///
    /// - Parameters:
    ///   - suiteView: image picker controller
    ///   - photo: photo has taken
    func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        let image = photo.sk.fixOrientation()
        self.jsInsertImage(images: [image], isOriginal: false)
    }

    /// user has take video,actually this will not happend, bez we don't support video insert
    ///
    /// - Parameters:
    ///   - suiteView: image picker controller
    ///   - url: vidoe url
    func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL) {

    }
}

extension DocsAssetToolBarItem {

    /// call front end's js to upload images
    ///
    /// - Parameter images: images to uplaod
    private func jsInsertImage(images: [UIImage], isOriginal: Bool) {
        var imageInfos: [String] = []
        let queue = DispatchQueue(label: "com.docs.jsinsertImage")
        images.forEach { (image) in
            queue.async {
                let uuid = self.makeUniqueId()
                let imageKey = self.makeImageCacheKey(with: uuid)
                let limitSize = isOriginal ? UInt.max : 2 * 1024 * 1024
                guard let data = image.data(quality: 1, limitSize: limitSize) as NSCoding? else { return }
                self.newCacheAPI.storeImage(data, token: nil, forKey: imageKey, needSync: true)
                if let info = self.makeImageInfoParas(uuid: uuid, image: image) {
                    imageInfos.append(info)
                }
            }
        }
        queue.async {
            DispatchQueue.main.async {
                let res = self.makeResJson(images: imageInfos, code: 0)
                if let name = DocsAssetToolBarItem.pickImageJsName {
                    self.jsEngine?.callFunction(DocsJSCallBack(name), params: res, completion: nil)
                }
                self.delegate?.requestHideToolBar(item: self)
            }
        }
    }

    /// uuid for each image
    ///
    /// - Returns: uuid
    private func makeUniqueId() -> String {
        let rawUUID = UUID().uuidString
        let uuid = rawUUID.replacingOccurrences(of: "-", with: "")
        return uuid.lowercased()
    }

    private func makeImageInfoParas(uuid: String, image: UIImage) -> String? {
        let res = ["uuid": uuid,
                   "src": DocSourceURLProtocolService.scheme + "://com.bytedance.net/file/f/" + uuid,
                   "width": "\(image.size.width * image.scale)px",
            "height": "\(image.size.height * image.scale)px"] as [String: Any]
        return res.jsonString
    }

    private func makeImageCacheKey(with uuid: String) -> String {
        return "/file/f/" + uuid
    }

    private func makeResJson(images imageArr: [String], code: Int) -> [String: Any] {
        return ["code": code,
                "thumbs": imageArr] as [String: Any]
    }
}
