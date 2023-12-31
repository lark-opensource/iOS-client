//
//  SKEditorPlugin+subHandler.swift
//  SKBrowser
//
//  Created by LiXiaolin on 2020/9/8.
//  


import Foundation
import LarkUIKit
import Photos
import Kingfisher
import SKResource
import SKCommon
import LarkAssetsBrowser
import ByteWebImage
import SKFoundation
import LarkSensitivityControl
import SKInfra

extension SKEditorPlugin {
    func addTitleViewToMainToolBar() -> ColorPickerNavigationView {
        let frame = CGRect(x: 0, y: 0, width: self.uiContainer?.frame.size.width ?? 0, height: 44)
        let titleView = ColorPickerNavigationView(frame: frame)
        titleView.titleLabel.text = BundleI18n.SKResource.Doc_Doc_ToolbarHighLight
        titleView.delegate = self
        toolbarManager.toolBar.setTitleView(titleView)
        toolbarManager.toolBar.hideBarContainer = true
        toolbarManager.toolBar.setTitleView(titleView)
        titleView.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(48)
        }
        titleView.exitAction = { [weak self] in
            self?.toolbarManager.toolBar.hideBarContainer = false
        }
        return titleView
    }

    func colorPickerNavigationViewRequestExit(view: ColorPickerNavigationView) {
        toolbarManager.toolBar.removeTitleView()
        self.currentSubPanel?.showRootView()
    }
}


// MARK: - docs 文本样式的支持
extension SKEditorPlugin: DocsAttributionViewDelegate, ColorPickerNavigationViewDelegate, SheetAttributionViewDelegate, SheetCellManagerViewDelegate {
    func docsAttributionView(getLarkFG key: String) -> Bool {
        return true
    }

    @discardableResult
    func docsAttributionViewDidShowColorPicker(view: DocsAttributionView) -> ColorPickerNavigationView {
        let view = addTitleViewToMainToolBar()
        view.titleLabel.text = BundleI18n.SKResource.Doc_Doc_ToolbarHighLight
        return view
    }

    func sheetAttributionViewDidShowImagePicker(view: SheetAttributionView) {
         addTitleViewToMainToolBar().titleLabel.text = BundleI18n.SKResource.Doc_Doc_ToolbarCellTxtColor
    }

    func sheetCellManagerViewDidShowImagePicker(view: SheetCellManagerView) {
        addTitleViewToMainToolBar().titleLabel.text = BundleI18n.SKResource.Doc_Doc_ToolbarCellBgColor
    }

    func docsAttributionView(change des: String, from panel: Bool) {

    }
}

// MARK: - 图片插入模块
extension SKEditorPlugin: AssetPickerSuiteViewDelegate {
    func handleAssetPicker(_ imagePickerView: DocsImagePickerToolView) {
        imagePickerView.suiteView?.delegate = self
        imagePickerView.suiteView?.onPresentBlock = { [weak self, weak imagePickerView] _ in
            guard let `self` = self else { return }
            self.toolbarManager.toolBar.requestAddRestoreTag(item: nil, tag: DocsAssetToolBarItem.restoreTag)
            if #available(iOS 17, *), SettingConfig.ios17CompatibleConfig?.fixInputViewIssue == true {
                //在图片选择器上弹出VC后键盘会下掉然后前端调用接口隐藏工具栏并设置inputView为nil
                //在iOS17上，上述操作会立刻将imagePickerToolView析构，导致弹出的VC马上被dismiss掉，所以这里先暂时持有下
                //注意，为避免内存泄漏需要在以下情景释放
                //finishSelect 图片选择完毕
                //didTakePhoto、didTakeVideo 拍照、视频完毕
                //cameraVCDidDismiss 相机视图控制器dismiss
                //imagePickerVCDidCancel 相册视图控制器dismiss
                self.imagePickerView = imagePickerView
            }
        }
        imagePickerView.suiteView?.finishSelectBlock = { [weak self] _, _ in
            guard let `self` = self else { return }
            self.toolbarManager.toolBar.requestAddRestoreTag(item: nil, tag: nil)
        }
        imagePickerView.suiteView?.cameraVCDidDismiss = { [weak self] in
            guard let `self` = self else { return }
            self.imagePickerView = nil
        }
        imagePickerView.suiteView?.imagePickerVCDidCancel = { [weak self] in
            guard let `self` = self else { return }
            self.imagePickerView = nil
        }
    }

    /// user has selected some photo from the album
    ///
    /// - Parameters:
    ///   - suiteView: image picker controller
    ///   - result: photo assest result
    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didFinishSelect result: AssetPickerSuiteSelectResult) {
        var images: [UIImage] = [UIImage]()
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        let assets = result.selectedAssets
        for asset in assets {
            do {
                if #available(iOS 13.0, *) {
                    _ = try AlbumEntry.requestImageDataAndOrientation(forToken: Token(PSDATokens.DocX.mini_app_insert_image_click_upload),
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
                    _ = try AlbumEntry.requestImageData(forToken: Token(PSDATokens.DocX.mini_app_insert_image_click_upload),
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
        self.imagePickerView = nil
        let params = [SkBasePickImagePlugin.imagesInfoKey: images,
                     SkBasePickImagePlugin.OriginalInfoKey: result.isOriginal] as [String: Any]
        simulateJSMessage(DocsJSService.simulateFinishPickingImage.rawValue, params: params)
    }

    /// user has take photo throught image picker controller
    ///
    /// - Parameters:
    ///   - suiteView: image picker controller
    ///   - photo: photo has taken
    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        self.imagePickerView = nil
        let image = photo.sk.fixOrientation()

        let params = [SkBasePickImagePlugin.imagesInfoKey: [image],
                      SkBasePickImagePlugin.OriginalInfoKey: false] as [String: Any]
        simulateJSMessage(DocsJSService.simulateFinishPickingImage.rawValue, params: params)
    }

    /// user has take video,actually this will not happend, bez we don't support video insert
    ///
    /// - Parameters:
    ///   - suiteView: image picker controller
    ///   - url: vidoe url
    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL) {
        self.imagePickerView = nil
    }
}
