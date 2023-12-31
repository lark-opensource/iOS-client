//
//  ImagePickerViewController.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/9/2.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import Photos
import RxSwift
import RxCocoa
import ByteWebImage
import LarkImageEditor
import LarkSensitivityControl
import UniverseDesignDialog

public enum ImagePickerAssetType {
    case imageOnly(maxCount: Int)
    case videoOnly(maxCount: Int)
    case imageOrVideo(imageMaxCount: Int, videoMaxCount: Int)
    case imageAndVideo(imageMaxCount: Int, videoMaxCount: Int)
    case imageAndVideoWithTotalCount(totalCount: Int)
}

extension ImagePickerAssetType {
    var maxCount: Int {
        switch self {
        case .imageOnly(let maxCount):
            return maxCount
        case .videoOnly(let maxCount):
            return maxCount
        case .imageOrVideo(let imageMaxCount, let videoMaxCount):
            // TODO: 暂时没用到，这里要根据已选择的 asset 类别判断
            return max(imageMaxCount, videoMaxCount)
        case .imageAndVideo(let imageMaxCount, let videoMaxCount):
            return imageMaxCount + videoMaxCount
        case .imageAndVideoWithTotalCount(let totalCount):
            return totalCount
        }
    }
}

public typealias ImagePickerPickResult = (selectedAssets: [PHAsset], isOriginal: Bool)

public final class ImagePickerViewController: UINavigationController {
    public var imageEditAction: ((ImageEditEvent) -> Void)?
    
    private var dataCenter: AlbumListDataCenter?
    
    let assetType: ImagePickerAssetType
    var fromMoment: Bool = false
    private var selectedAssets: [PHAsset]
    
    private let isOriginButtonHidden: Bool
    private var isOriginal: Bool
    /// 选择视频时，是否支持点击"原图"按钮
    private let originVideo: Bool
    private let sendButtonTitle: String
    private let takePhotoEnable: Bool
    
    /// 是否支持视频编辑
    var supportVideoEditor: Bool = false
    
    let imageCache: ImageCache
    let editImageCache: EditImageCache
    let editVideoCache: EditVideoCache
    
    lazy var selectedAssetsSubject: BehaviorRelay<[PHAsset]> = {
        return BehaviorRelay(value: selectedAssets)
    }()
    
    weak var toolBarDelegate: PhotoPickerBottomToolBarDelegate?
    var toolBar: PhotoPickerBottomToolBar?
    lazy var isOriginalSubject: BehaviorRelay<Bool> = {
        return BehaviorRelay(value: isOriginal)
    }()
    
    private let queue = OperationQueue()
    
    public var imagePickerFinishSelect: ((ImagePickerViewController, ImagePickerPickResult) -> Void)?
    public var imagePickerSelectChange: ((ImagePickerViewController, ImagePickerPickResult) -> Void)?
    public var imagePickerDidPreview: ((ImagePickerViewController, PHAsset) -> Void)?
    public var imagePikcerCancelSelect: ((ImagePickerViewController, ImagePickerPickResult) -> Void)?
    public var imagePickerFinishTakePhoto: ((ImagePickerViewController, UIImage) -> Void)?
    public var imagePickerClickEdit: (() -> Void)?
    public var videoPickerClickEdit: (() -> Void)?
    public var imagePickerClickOriginInPreview: ((ImagePickerPickResult) -> Void)?
    public var imagePickerShowAssetsBrowse: (() -> Void)?
    public var reachMaxCountTipBlock: ((PhotoPickerSelectDisableType) -> String?)?
    /// 选择图片组件
    ///
    /// - Parameters:
    ///   - assetType: 选择资源的类型
    ///   - selectedAssets: 选中的资源
    ///   - isOriginal: 是否原图
    ///   - isOriginButtonHidden: 原图按钮是否隐藏
    ///   - sendButtonTitle: 发送按钮title
    ///   - takePhotoEnable: 是否允许拍照
    ///   - editImageCache: 编辑图片缓存（不需要传空即可）
    public init(assetType: ImagePickerAssetType = .imageOrVideo(imageMaxCount: 9, videoMaxCount: 1),
                selectedAssets: [PHAsset] = [],
                isOriginal: Bool = true,
                isOriginButtonHidden: Bool = false,
                originVideo: Bool = false,
                sendButtonTitle: String? = nil,
                takePhotoEnable: Bool = true,
                imageCache: ImageCache = ImageCache(),
                editImageCache: EditImageCache? = nil
    ) {
        self.assetType = assetType
        self.selectedAssets = selectedAssets
        self.isOriginal = isOriginal
        self.isOriginButtonHidden = isOriginButtonHidden
        
        self.originVideo = originVideo
        self.sendButtonTitle = sendButtonTitle ?? BundleI18n.LarkAssetsBrowser.Lark_Legacy_Send
        self.takePhotoEnable = takePhotoEnable
        self.imageCache = imageCache
        self.editImageCache = editImageCache ?? EditImageCache()
        self.editVideoCache = EditVideoCache()
        
        super.init(nibName: nil, bundle: nil)
        
        queue.isSuspended = true
    }
    
    public init(assetType: ImagePickerAssetType = .imageOrVideo(imageMaxCount: 9, videoMaxCount: 1),
                selectedAssets: [PHAsset] = [],
                isOriginal: Bool = false,
                isOriginButtonHidden: Bool = false,
                originVideo: Bool = false,
                sendButtonTitle: String? = nil,
                takePhotoEnable: Bool = false,
                imageCache: ImageCache = ImageCache(),
                editImageCache: EditImageCache? = nil,
                editVideoCache: EditVideoCache?
    ) {
        self.assetType = assetType
        self.selectedAssets = selectedAssets
        self.isOriginal = isOriginal
        self.isOriginButtonHidden = isOriginButtonHidden
        
        self.originVideo = originVideo
        self.sendButtonTitle = sendButtonTitle ?? BundleI18n.LarkAssetsBrowser.Lark_Legacy_Send
        self.takePhotoEnable = takePhotoEnable
        self.imageCache = imageCache
        self.editImageCache = editImageCache ?? EditImageCache()
        self.editVideoCache = editVideoCache ?? EditVideoCache()
        
        super.init(nibName: nil, bundle: nil)
        
        queue.isSuspended = true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.ud.bgBase

        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .notDetermined:
            try? AlbumEntry.requestAuthorization(forToken: AssetBrowserToken.requestAuthorization.token) { (status) in
                DispatchQueue.global().async {
                    self.dataCenter = AlbumListDataCenter(assetType: self.assetType)
                    self.queue.isSuspended = false
                }
                if status != .authorized {
                    self.showRequestAuthorizationAlert()
                }
            }
        case .restricted, .denied:
            DispatchQueue.global().async {
                self.dataCenter = AlbumListDataCenter(assetType: self.assetType)
                self.queue.isSuspended = false
            }
            showRequestAuthorizationAlert()
        case .authorized:
            DispatchQueue.global().async {
                self.dataCenter = AlbumListDataCenter(assetType: self.assetType)
                self.queue.isSuspended = false
            }
#if canImport(WidgetKit)
        case .limited:
            DispatchQueue.global().async {
                self.dataCenter = AlbumListDataCenter(assetType: self.assetType)
                self.queue.isSuspended = false
            }
#endif
        @unknown default:
            break
        }
    }
    
    private func showRequestAuthorizationAlert() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let dialog = UDDialog.noPermissionDialog(
                title: BundleI18n.LarkAssetsBrowser.Lark_Core_PhotoAccessForSavePhoto,
                detail: BundleI18n.LarkAssetsBrowser.Lark_Core_EnablePhotoAccess_ChangeProfilePhoto(),
                onClickCancel: { [weak self] in
                    guard let self = self else { return }
                    self.imagePikcerCancelSelect?(self, (self.selectedAssets, self.isOriginal))
            }, onClickGoToSetting: { [weak self] in
                guard let self = self else { return }
                self.imagePikcerCancelSelect?(self, (self.selectedAssets, self.isOriginal))
            })
            self.present(dialog, animated: true, completion: nil)
        }
    }
    
    private func addTask(_ task: @escaping () -> Void) {
        queue.addOperation {
            DispatchQueue.main.async {
                task()
            }
        }
    }
    
    public func showSingleSelectAssetGridViewController() {
        addTask { [weak self] in
            guard let `self` = self, let dataCenter = self.dataCenter else { return }
            let assetGridViewController = AssetGridSingleSelectViewController(dataCenter: dataCenter)
            assetGridViewController.delegate = self
            assetGridViewController.reachMaxCountTipBlock = self.reachMaxCountTipBlock
            self.pushViewController(assetGridViewController, animated: false)
        }
    }
    
    /// 点击相册的按钮
    public func showMultiSelectAssetGridViewController() {
        addTask { [weak self] in
            guard let `self` = self, let dataCenter = self.dataCenter else { return }
            var bottomConfig = ImagePickerBottomViewConfig.lightDefault
            bottomConfig.sendButtonTitle = self.sendButtonTitle
            bottomConfig.originButtonHidden = self.isOriginButtonHidden
            bottomConfig.originButtonSelected = self.isOriginal
            let assetGridViewController = AssetGridMultiSelectController(dataCenter: dataCenter,
                                                                         originVideo: self.originVideo,
                                                                         bottomViewConfig: bottomConfig,
                                                                         takePhotoEnable: self.takePhotoEnable)
            assetGridViewController.delegate = self
            assetGridViewController.toolBar = self.toolBar
            assetGridViewController.toolBarDelegate = self.toolBarDelegate
            assetGridViewController.reachMaxCountTipBlock = self.reachMaxCountTipBlock
            assetGridViewController.supportVideoEditor = self.supportVideoEditor
            self.pushViewController(assetGridViewController, animated: false)
        }
    }
    /// 点击预览
    /// 预览一张图片，可以左右滑动查看相册中其它图片
    ///
    /// - Parameter asset: 要预览的图片
    internal func showAssetBrowseViewController(withAsset asset: PHAsset) {
        self.imagePickerShowAssetsBrowse?()
        
        addTask {
            guard let dataCenter = self.dataCenter else { return }
            var bottomConfig = ImagePickerBottomViewConfig.darkDefault
            bottomConfig.sendButtonTitle = self.sendButtonTitle
            bottomConfig.originButtonHidden = self.isOriginButtonHidden
            bottomConfig.originButtonSelected = self.isOriginal
            
            let album = (dataCenter.defaultAlbum ?? Album.empty).reversed
            let assetPreviewController = AssetPreviewViewController(album: album,
                                                                    index: album.index(of: asset),
                                                                    originVideo: self.originVideo,
                                                                    bottomViewConfig: bottomConfig)
            assetPreviewController.delegate = self
            assetPreviewController.toolBar = self.toolBar
            assetPreviewController.toolBarDelegate = self.toolBarDelegate
            assetPreviewController.reachMaxCountTipBlock = self.reachMaxCountTipBlock
            assetPreviewController.supportVideoEditor = self.supportVideoEditor
            self.pushViewController(assetPreviewController, animated: false)
        }
    }
    
    /// 预览选中的图片，左右滑动预览选中的其它图片
    ///
    /// - Parameter assets: 选中的图片
    internal func showAssetBrowseViewController(withSelectAssets assets: [PHAsset]) {
        self.imagePickerShowAssetsBrowse?()
        
        addTask {
            var bottomConfig = ImagePickerBottomViewConfig.darkDefault
            bottomConfig.sendButtonTitle = self.sendButtonTitle
            bottomConfig.originButtonHidden = self.isOriginButtonHidden
            bottomConfig.originButtonSelected = self.isOriginal
            
            let collection = PHAssetCollection.transientAssetCollection(with: self.selectedAssets, title: nil)
            let fetchResult = PHAsset.fetchAssets(in: collection, options: nil)
            let album = Album(collection: collection, fetchResult: fetchResult)
            let assetPreviewController = AssetPreviewViewController(album: album,
                                                                    index: 0,
                                                                    originVideo: self.originVideo,
                                                                    bottomViewConfig: bottomConfig)
            assetPreviewController.delegate = self
            assetPreviewController.toolBar = self.toolBar
            assetPreviewController.toolBarDelegate = self.toolBarDelegate
            assetPreviewController.reachMaxCountTipBlock = self.reachMaxCountTipBlock
            assetPreviewController.supportVideoEditor = self.supportVideoEditor
            self.pushViewController(assetPreviewController, animated: false)
        }
    }
}

extension ImagePickerViewController: AssetPickerSubViewControllerDelegate {
    func assetVCSelectDidChange(_ assetVC: AssetPickerSubViewController) {
        self.imagePickerSelectChange?(self,
                                      ImagePickerPickResult(selectedAssets: selectedAssetsSubject.value,
                                                            isOriginal: isOriginalSubject.value))
    }
    
    func assetVCOriginButtonDidClick(_ assetVC: AssetPickerSubViewController) {
        self.imagePickerClickOriginInPreview?(ImagePickerPickResult(selectedAssets: selectedAssetsSubject.value,
                                                                    isOriginal: isOriginalSubject.value))
    }
    
    func assetVCCenterButtonDidClick(_ assetVC: AssetPickerSubViewController, isImage: Bool) {
        if isImage {
            self.imagePickerClickEdit?()
        } else {
            self.videoPickerClickEdit?()
        }
    }
    
    func assetVCCancelButtonDidClick(_ assetVC: AssetPickerSubViewController) {
        let selectedAssets = selectedAssetsSubject.value
        selectedAssets.forEach { (asset) in
            asset.editImage = editImageCache.editImage(key: asset.localIdentifier)
            asset.editVideo = editVideoCache.editVideo(key: asset.localIdentifier)
        }
        if let cancelSelect = imagePikcerCancelSelect {
            cancelSelect(self, ImagePickerPickResult(selectedAssets: selectedAssets,
                                                     isOriginal: isOriginalSubject.value))
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func assetVCSendButtonDidClick(_ assetVC: AssetPickerSubViewController) {
        let selectedAssets = selectedAssetsSubject.value
        selectedAssets.forEach { (asset) in
            asset.editImage = editImageCache.editImage(key: asset.localIdentifier)
            asset.editVideo = editVideoCache.editVideo(key: asset.localIdentifier)
        }
        imagePickerFinishSelect?(self,
                                 ImagePickerPickResult(selectedAssets: selectedAssetsSubject.value,
                                                       isOriginal: isOriginalSubject.value))
    }
    
    func assetVC(_ assetVC: AssetPickerSubViewController, didFinishPicture image: UIImage) {
        imagePickerFinishTakePhoto?(self, image)
    }

    func assetVC(_ assetVC: AssetPickerSubViewController, didPreview asset: PHAsset) {
        imagePickerDidPreview?(self, asset)
    }
}
