//
//  AssetPickerSuiteView.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/9/6.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LKCommonsLogging
import Photos
import RxSwift
import AVFoundation
import LarkEMM
import LarkFoundation
import LarkMonitor
import LarkSetting
import LarkContainer
import LarkImageEditor
import LarkUIKit
import LarkStorage
import ByteWebImage
import UniverseDesignDialog
import LarkVideoDirector
import EENavigator
import RxCocoa

public typealias AssetPickerSuiteSelectResult = (selectedAssets: [PHAsset], isOriginal: Bool)

public protocol AssetPickerSuiteViewDelegate: AnyObject {
    func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didFinishSelect result: AssetPickerSuiteSelectResult)
    func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakePhoto photo: UIImage)
    func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didTakeVideo url: URL)
    func assetPickerSuite(_ clickType: AssetPickerSuiteClickType)
    func assetPickerSuite(_ previewClickType: AssetPickerPreviewClickType)
    func assetPickerSuiteShouldUpdateHeight(_ suiteView: AssetPickerSuiteView)
    func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didChangeSelection result: AssetPickerSuiteSelectResult)
    func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didPreview asset: PHAsset)
}

public extension AssetPickerSuiteViewDelegate {
    func assetPickerSuite(_ clickType: AssetPickerSuiteClickType) {}
    func assetPickerSuite(_ previewClickType: AssetPickerPreviewClickType) {}
    func assetPickerSuiteShouldUpdateHeight(_ suiteView: AssetPickerSuiteView) {}
    func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didChangeSelection result: AssetPickerSuiteSelectResult) {}
    func assetPickerSuite(_ suiteView: AssetPickerSuiteView, didPreview asset: PHAsset) {}
}

/// 使用的相机类型
public enum CameraType {
    /// 系统相机
    case system
    /// 系统相机（是否自动保存拍摄结果到相册）
    case systemAutoSave(_ isAutoSaveToAlbum: Bool)
    /// 自定义相机（是否自动保存拍摄结果到相册）
    case custom(_ isAutoSaveToAlbum: Bool)

    var shouldAutoSaveResult: Bool {
        switch self {
        case .system:
            return false
        case .systemAutoSave(let autoSave):
            return autoSave
        case .custom(let autoSave):
            return autoSave
        }
    }
}

public enum AssetPickerSuiteClickType: String {
    case camera /// 用户点击 IM 中输入框图片的相机
    case view /// 用户点击 IM 中输入框图片的图片浏览
    case picture /// 用户点击 IM 中输入框图片的原图
    case preview /// 用户点击 IM 中输入框图片的预览
    case send /// 用户点击 IM 中输入框图片的发送
}

public enum AssetPickerPreviewClickType: String {
    case origin /// 用户点击Picker图片的原图
    case previewImage /// 用户点击Picker图片
    case sendImage /// 用户点击预览图片的发送
    case editImage /// 用户点击预览图片的编辑
    case editVideo /// 用户点击预览视频的编辑
}

public final class AssetPickerSuiteView: UIView {
    static let logger = Logger.log(AssetPickerSuiteView.self, category: "Module.LarkUIKit.AssetPickerSuiteView")
    private let _store = KVStores.udkv(space: .global, domain: Domain.biz.core.child("AssetsPicker"))
    private static let store = \AssetPickerSuiteView._store
    @KVBinding(to: store, key: "hasShowPrevent", default: false)
    var hasShowPrevent: Bool

    public weak var delegate: AssetPickerSuiteViewDelegate?
    public var imageEditAction: ((ImageEditEvent) -> Void)?
    public var onPresentBlock: ((AssetPickerSuiteView) -> Void)?
    public var finishSelectBlock: ((AssetPickerSuiteView, AssetPickerSuiteSelectResult) -> Void)?
    public var takePhotoBlock: ((AssetPickerSuiteView, UIImage) -> Void)?
    public var takeVideoBlock: ((AssetPickerSuiteView, URL) -> Void)?
    public var photoPickerReloadBlock: ((PHFetchResult<PHAsset>) -> Void)?
    public var cameraVCDidDismiss: (() -> Void)?
    public var imagePickerVCDidCancel: (() -> Void)?

    private var cameraPhotoDidFinishEdittingBlock: ((UIImage) -> Void)?
    private var cameraPhotoDidQuitEdittingBlock: (() -> Void)?
    public var reachMaxCountTipBlock: ((PhotoPickerSelectDisableType) -> String?)? {
        didSet {
            pickView.reachMaxCountTipBlock = reachMaxCountTipBlock
        }
    }
    public var fromMoment: Bool = false {
        didSet {
            pickView.fromMoment = fromMoment
        }
    }
    public let imageCache = ImageCache()

    /// 是否支持视频编辑
    public var supportVideoEditor: Bool = false

    /// 由于 AssetPickerSuiteView 是一个 UIView，所以需要接入方传入一个 UIViewController，以便在其上方弹出其他页面。
    /// 一般传入 AssetPickerSuiteView 所添加到的 VC 即可。
    public var presentVC: UIViewController? {
        get { vcForPresentation }
        set { vcForPresentation = newValue }
    }

    private var assetType: PhotoPickerAssetType
    private let cameraType: CameraType
    private let sendButtonTitle: String
    private let isOriginalButtonHidden: Bool
    /// 选择视频时，是否支持点击"原图"按钮
    private let originVideo: Bool
    private weak var vcForPresentation: UIViewController?
    private let modalPresentationStyle: UIModalPresentationStyle

    private let cache = EditImageCache()
    private let videoEditorCache = EditVideoCache()

    private let pickView: PhotoPickView
    private weak var presentedPickerVC: UIViewController?

    private let audioQueue = DispatchQueue(label: "asset.picker.suite.view.queue")

    /// AssetPickerSuiteView初始化方法
    ///
    /// - Parameters:
    ///   - assetType: 选择资源的类型
    ///   - cameraType: 相机的类型
    ///   - sendButtonTitle: 右下角发送按钮的title
    ///   - isOriginalButtonHidden: 是否显示原图按钮
    ///   - presentVC: 用来present图片选择器、拍照界面的VC
    public init(assetType: PhotoPickerAssetType = PhotoPickerAssetType.default,
                originVideo: Bool = false,
                cameraType: CameraType = .system,
                sendButtonTitle: String? = nil,
                isOriginalButtonHidden: Bool = false,
                presentVC: UIViewController? = nil,
                modalPresentationStyle: UIModalPresentationStyle = .overFullScreen) {
        self.assetType = assetType
        self.cameraType = cameraType
        self.originVideo = originVideo
        self.sendButtonTitle = sendButtonTitle ?? BundleI18n.LarkAssetsBrowser.Lark_Legacy_Send
        self.isOriginalButtonHidden = isOriginalButtonHidden
        self.vcForPresentation = presentVC
        self.modalPresentationStyle = modalPresentationStyle

        let cache = self.cache
        let videoEditorCache = self.videoEditorCache
        pickView = PhotoPickView(assetType: assetType,
                                 originVideo: originVideo,
                                 isOriginalButtonHidden: isOriginalButtonHidden,
                                 sendButtonTitle: self.sendButtonTitle,
                                 imageCache: imageCache,
                                 editImage: { cache.editImage(key: $0) },
                                 editVideo: { videoEditorCache.editVideo(key: $0) })

        super.init(frame: .zero)

        addSubview(pickView)
        pickView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        pickView.delegate = self
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        presentedPickerVC?.dismiss(animated: false)
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        pickView.show()
    }

    /// 清除assetPicker选择状态
    public func reset() {
        pickView.clear()
        pickView.show()
    }

    /// 对外暴漏 isOrigin 接口
    public func set(isOrigin: Bool) {
        pickView.set(isOrigin: isOrigin)
    }

    /// 支持动态更新最大图片数
    /// - Parameter type: 最大选择数
    public func updateAssetType(_ type: PhotoPickerAssetType) {
        assetType = type
        pickView.updateAssetType(type)
    }

    public func updateBottomOffset(_ offset: CGFloat) {
        pickView.bottomOffset = offset
    }

    /// 更新assetPicker高度
    public func update(height: CGFloat) {
        pickView.update(height: height)
    }

    private func showImagePickerWith(selectedAssets: [PHAsset], isOriginal: Bool, gotoAssetBrowseDirectly: Bool, previewAsset: PHAsset?) {
        let assetType: ImagePickerAssetType
        switch self.assetType {
        case .imageOnly(maxCount: let maxCount):
            assetType = .imageOnly(maxCount: maxCount)
        case .videoOnly(maxCount: let maxCount):
            assetType = .videoOnly(maxCount: maxCount)
        case .imageOrVideo(imageMaxCount: let imageMaxCount, videoMaxCount: let videoMaxCount):
            assetType = .imageOrVideo(imageMaxCount: imageMaxCount, videoMaxCount: videoMaxCount)
        case .imageAndVideo(imageMaxCount: let imageMaxCount, videoMaxCount: let videoMaxCount):
            assetType = .imageAndVideo(imageMaxCount: imageMaxCount, videoMaxCount: videoMaxCount)
        case .imageAndVideoWithTotalCount(totalCount: let totalCount):
            assetType = .imageAndVideoWithTotalCount(totalCount: totalCount)
        }
        let imagePicker = ImagePickerViewController(assetType: assetType,
                                                    selectedAssets: selectedAssets,
                                                    isOriginal: isOriginal,
                                                    isOriginButtonHidden: self.isOriginalButtonHidden,
                                                    originVideo: self.originVideo,
                                                    sendButtonTitle: sendButtonTitle,
                                                    imageCache: imageCache,
                                                    editImageCache: cache,
                                                    editVideoCache: self.videoEditorCache)
        imagePicker.imageEditAction = imageEditAction
        imagePicker.fromMoment = fromMoment
        imagePicker.toolBar = self.pickView.bottomToolBar
        imagePicker.toolBarDelegate = self.pickView.bottomToolBar.delegate
        imagePicker.imagePickerFinishSelect = { [weak self] (picker, result) in
            guard let `self` = self else { return }
            self.delegate?.assetPickerSuite(.sendImage)
            let selectResult = AssetPickerSuiteSelectResult(selectedAssets: result.selectedAssets,
                                                            isOriginal: result.isOriginal)
            self.cache.removeAll()
            self.videoEditorCache.removeAll()
            self.pickView.clear()
            self.finishSelectBlock?(self, selectResult)
            self.delegate?.assetPickerSuite(self, didFinishSelect: selectResult)
            picker.dismiss(animated: true, completion: nil)
        }

        imagePicker.imagePikcerCancelSelect = { [weak self] (picker, result) in
            self?.pickView.setSelected(items: result.selectedAssets,
                                       useOriginal: result.isOriginal)
            self?.imagePickerVCDidCancel?()
            picker.dismiss(animated: true, completion: nil)
        }

        imagePicker.imagePickerClickEdit = { [weak self] in
            self?.delegate?.assetPickerSuite(.editImage)
        }

        imagePicker.videoPickerClickEdit = { [weak self] in
            self?.delegate?.assetPickerSuite(.editVideo)
        }

        imagePicker.imagePickerClickOriginInPreview = { [weak self] result in
            self?.delegate?.assetPickerSuite(.origin)
            self?.pickView.setSelected(items: result.selectedAssets, useOriginal: result.isOriginal)
        }

        imagePicker.imagePickerShowAssetsBrowse = { [weak self] in
            self?.delegate?.assetPickerSuite(.previewImage)
        }

        imagePicker.imagePickerSelectChange = { [weak self] (_, result) in
            guard let `self` = self else { return }
            let selectResult = AssetPickerSuiteSelectResult(selectedAssets: result.selectedAssets,
                                                            isOriginal: result.isOriginal)
            self.delegate?.assetPickerSuite(self, didChangeSelection: selectResult)
            self.pickView.setSelected(items: result.selectedAssets, useOriginal: result.isOriginal)
        }

        imagePicker.imagePickerDidPreview = { [weak self] (_, asset) in
            guard let self else { return }
            self.delegate?.assetPickerSuite(self, didPreview: asset)
        }

        if gotoAssetBrowseDirectly {
            if let previewAsset = previewAsset {
                imagePicker.showAssetBrowseViewController(withAsset: previewAsset)
            } else {
                imagePicker.showAssetBrowseViewController(withSelectAssets: selectedAssets)
            }
        } else {
            imagePicker.showMultiSelectAssetGridViewController()
        }
        onPresentBlock?(self)
        imagePicker.modalPresentationStyle = modalPresentationStyle
        imagePicker.reachMaxCountTipBlock = reachMaxCountTipBlock
        imagePicker.supportVideoEditor = self.supportVideoEditor
        present(imagePicker, animated: true, completion: nil)
        self.presentedPickerVC = imagePicker
    }

    private func present(_ viewControllerToPresent: UIViewController,
                         animated flag: Bool,
                         completion: (() -> Void)? = nil) {
        let vc = vcForPresentation ?? LKAssetBrowserUtils.topViewControllerFrom(view: self)
        vc?.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}

extension AssetPickerSuiteView: PhotoPickViewDelegate {

    public func shouldReload() {
        delegate?.assetPickerSuiteShouldUpdateHeight(self)
    }

    public func goSetting() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    public func takePhoto() {
        var config = LarkCameraKit.CameraConfig()
        switch cameraType {
        case .system, .systemAutoSave:
            config.cameraType = .system
        case .custom:
            config.cameraType = .automatic
            switch assetType {
            case .imageOnly:
                config.mediaType = .photoOnly
            case .videoOnly:
                config.mediaType = .videoOnly
            case .imageOrVideo, .imageAndVideo, .imageAndVideoWithTotalCount:
                config.mediaType = .photoAndVideo
            }
        }
        config.autoSave = self.cameraType.shouldAutoSaveResult
        config.afterTakePhotoAction = .enterImageEditor
        config.didCancel = { [weak self] _ in
            self?.cameraVCDidDismiss?()
        }
        config.didTakePhoto = { [weak self] image, vc, _, _ in
            guard let self else { return }
            self.takePhotoBlock?(self, image)
            self.delegate?.assetPickerSuite(self, didTakePhoto: image)
            vc.dismiss(animated: true)
        }
        config.didRecordVideo = { [weak self] videoURL, vc, _, _ in
            guard let self else { return }
            self.takeVideoBlock?(self, videoURL)
            self.delegate?.assetPickerSuite(self, didTakeVideo: videoURL)
            vc.dismiss(animated: true)
        }
        config.showDialogWhenCreatingFailed = true
        let userResolver = Container.shared.getCurrentUserResolver()
        guard let vc = vcForPresentation ?? LKAssetBrowserUtils.topViewControllerFrom(view: self) else {
            Self.logger.error("cannot find vc from asset picker: \(self)")
            return
        }
        LarkCameraKit.createCamera(with: config, from: vc, userResolver: userResolver) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let camera):
                self.delegate?.assetPickerSuite(.camera)
                self.onPresentBlock?(self)
                camera.modalPresentationStyle = self.modalPresentationStyle
                self.present(camera, animated: true)
                self.presentedPickerVC = camera
            case .failure:
                break
            }
        }
    }

    public func clickOriginButton() {
        self.delegate?.assetPickerSuite(.picture)
    }

    public func showPhotoLibrary(selectedItems: [PHAsset], useOriginal: Bool) {
        // 增加阻断逻辑
        let style = PhotoPickView.preventStyle
        if style == .denied || (style == .limited && !self.hasShowPrevent) {
            if style == .limited {
                self.hasShowPrevent = true
            }
            let preventContoller = LimitPreventController(with: style)
            preventContoller.modalPresentationStyle = .overFullScreen
            preventContoller.closeClosure = {

            }
            preventContoller.continueClosure = {
                // Doc 场景 suitView会随着键盘消失被释放，所以强引用，必报合LimitPreventController生命周期绑定的
                // 存在循环引用也会因为Controller的Dismiss而解除
                self.delegate?.assetPickerSuite(.view)
                self.showImagePickerWith(selectedAssets: selectedItems,
                                         isOriginal: useOriginal,
                                         gotoAssetBrowseDirectly: false,
                                         previewAsset: nil)
            }
            preventContoller.goSettingClosure = {
                self.goSetting()
            }
            present(preventContoller, animated: true)
        } else {
            self.delegate?.assetPickerSuite(.view)
            showImagePickerWith(selectedAssets: selectedItems,
                                isOriginal: useOriginal,
                                gotoAssetBrowseDirectly: false,
                                previewAsset: nil)
        }
    }

    public func preview(asset: PHAsset, selectedImages: [PHAsset], useOriginal: Bool) {
        showImagePickerWith(selectedAssets: selectedImages,
                            isOriginal: useOriginal,
                            gotoAssetBrowseDirectly: true,
                            previewAsset: asset)
    }

    public func preview(selectedItems: [PHAsset], useOriginal: Bool) {
        self.delegate?.assetPickerSuite(.preview)
        showImagePickerWith(selectedAssets: selectedItems,
                            isOriginal: useOriginal,
                            gotoAssetBrowseDirectly: true,
                            previewAsset: nil)
    }

    public func pickedImages(images: [PHAsset], useOriginal: Bool) {
        images.forEach { (asset) in
            asset.editImage = cache.editImage(key: asset.localIdentifier)
            asset.editVideo = videoEditorCache.editVideo(key: asset.localIdentifier)
        }
        self.delegate?.assetPickerSuite(.send)
        cache.removeAll()
        videoEditorCache.removeAll()
        pickView.reload()
        let selectResult = AssetPickerSuiteSelectResult(selectedAssets: images,
                                                        isOriginal: useOriginal)
        self.finishSelectBlock?(self, selectResult)
        self.delegate?.assetPickerSuite(self, didFinishSelect: selectResult)
    }

    public func pickedImagesChange(images: [PHAsset], useOriginal: Bool) {
        let selectResult = AssetPickerSuiteSelectResult(selectedAssets: images,
                                                        isOriginal: useOriginal)
        self.delegate?.assetPickerSuite(self, didChangeSelection: selectResult)
    }

    public func photoPickerReload(with assetResult: PHFetchResult<PHAsset>) {
        self.photoPickerReloadBlock?(assetResult)
    }

    private static func execInMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}

