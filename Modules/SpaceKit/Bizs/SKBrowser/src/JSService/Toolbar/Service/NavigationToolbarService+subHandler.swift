//
//  NavigationToolbarService+SubToolBar.swift
//  SpaceKit
//
//  Created by Webster on 2019/5/28.
//

import Foundation
import LarkUIKit
import Photos
import Kingfisher
import SKCommon
import SKResource
import SKFoundation
import LarkAssetsBrowser
import UIKit
import SKInfra

// MARK: - docs 文本样式的支持
extension NavigationToolbarService: DocsAttributionViewDelegate, ColorPickerNavigationViewDelegate, SheetAttributionViewDelegate, SheetCellManagerViewDelegate {
    func docsAttributionView(getLarkFG key: String) -> Bool {
        return model?.jsEngine.fetchServiceInstance(FgConfigChange.self)?.getLarkFG(for: key) ?? false
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
        guard let info = model?.browserInfo.docsInfo else { return }
        var actionName = ""
        var params: [String: String] = ["file_id": DocsTracker.encrypt(id: info.objToken),
                                        "file_type": info.type.name,
                                        "mode": "default",
                                        "module": info.type.name]
        if des == ColorPaletteItemType.clear.mappedValue() {
            actionName = "highlight_cancel"
        } else {
            actionName = panel ? "highlight_switch_color" : "highlight_default"
            params["op_item"] = des
        }
        params["action"] = actionName

        DocsTracker.log(enumEvent: DocsTracker.EventType.toggleAttribute, parameters: params)
    }
}

// MARK: - 图片插入模块
extension NavigationToolbarService: AssetPickerSuiteViewDelegate {
    func handleAssetPicker(_ imagePickerView: DocsImagePickerToolView) {
        imagePickerView.suiteView?.delegate = self
        imagePickerView.presentVC = self.navigator?.currentBrowserVC
        imagePickerView.suiteView?.onPresentBlock = { [weak self, weak imagePickerView] _ in
            guard let `self` = self else { return }
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
            self.tool?.toolBar.requestAddRestoreTag(item: nil, tag: nil)
        }
        imagePickerView.suiteView?.finishSelectBlock = { [weak self] _, _ in
            guard let `self` = self else { return }
            self.tool?.toolBar.requestAddRestoreTag(item: nil, tag: nil)
        }
        imagePickerView.suiteView?.takePhotoBlock = { [weak self] _, _ in
            guard let `self` = self else { return }
            self.tool?.toolBar.requestAddRestoreTag(item: nil, tag: nil)
        }
        imagePickerView.suiteView?.takeVideoBlock = { [weak self] _, _ in
            guard let `self` = self else { return }
            self.tool?.toolBar.requestAddRestoreTag(item: nil, tag: nil)
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
        let assets = result.selectedAssets
        let orignal = result.isOriginal
        let params = [SKPickContent.pickContent: SKPickContent.asset(assets: assets, original: orignal)]
        DocsTracker.log(enumEvent: .imgPickerConfirm, parameters: ["event": "selectImages", "count": assets.count])
        self.model?.jsEngine.simulateJSMessage(DocsJSService.simulateFinishPickFile.rawValue, params: params)
        self.imagePickerView = nil
    }

    /// user has take photo throught image picker controller
    ///
    /// - Parameters:
    ///   - suiteView: image picker controller
    ///   - photo: photo has taken
    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage) {
        let params = [SKPickContent.pickContent: SKPickContent.takePhoto(photo: photo)]
        DocsTracker.log(enumEvent: .imgPickerConfirm, parameters: ["event": "selectImages", "count": Int(1)])
        self.model?.jsEngine.simulateJSMessage(DocsJSService.simulateFinishPickFile.rawValue, params: params)
        self.imagePickerView = nil
    }

    /// user has take video,actually this will not happend, bez we don't support video insert
    ///
    /// - Parameters:
    ///   - suiteView: image picker controller
    ///   - url: vidoe url
    public func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL) {
        let params = [SKPickContent.pickContent: SKPickContent.takeVideo(videoUrl: url)]
        self.model?.jsEngine.simulateJSMessage(DocsJSService.simulateFinishPickFile.rawValue, params: params)
        self.imagePickerView = nil
    }


    public func assetPickerSuite(_ clickType: AssetPickerSuiteClickType) {
        if (clickType == .view || clickType == .camera),
           let browserVC = navigator?.currentBrowserVC as? BrowserViewController {
            DocsLogger.info("工具栏图片查看器进入图片选择全屏模式，browserVC抢占原先在webview上的焦点")
            browserVC.becomeFirstResponderFromEditorView()
        }
    }


    public func assetPickerSuite(_ previewClickType: AssetPickerPreviewClickType) {
        if previewClickType == .previewImage,
           let browserVC = navigator?.currentBrowserVC as? BrowserViewController {
            DocsLogger.info("工具栏图片查看器进入图片预览模式，browserVC抢占原先在webview上的焦点")
            browserVC.becomeFirstResponderFromEditorView()
        }
    }
}

extension NavigationToolbarService {
    func addTitleViewToMainToolBar() -> ColorPickerNavigationView {
        let frame = CGRect(x: 0, y: 0, width: Display.width, height: 48)
        let titleView = ColorPickerNavigationView(frame: frame)
        titleView.titleLabel.text = BundleI18n.SKResource.Doc_Doc_ToolbarHighLight
        titleView.delegate = self
        tool?.toolBar.hideBarContainer = true
        tool?.toolBar.setTitleView(titleView)
        titleView.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(48)
        }
        titleView.exitAction = { [weak self] in
            self?.tool?.toolBar.hideBarContainer = false
        }
        return titleView
    }

    func colorPickerNavigationViewRequestExit(view: ColorPickerNavigationView) {
        tool?.toolBar.removeTitleView()
        self.currentSubPanel?.showRootView()
    }
}
