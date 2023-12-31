//
//  AssetPreviewViewController.swift
//  LarkImagePicker
//
//  Created by ChalrieSu on 2018/8/31.
//  Copyright © 2018 ChalrieSu. All rights reserved.
//

import Foundation
import UIKit
import Photos
import SnapKit
import LarkExtensions
import ByteWebImage
import LarkUIKit
import LarkImageEditor
import UniverseDesignToast
import LarkVideoDirector
import LarkFeatureGating
import LarkSensitivityControl
import LarkSceneManager
import LKCommonsLogging
import LarkStorage
import EENavigator
import LarkMedia
import UniverseDesignDialog

final class AssetPreviewViewController: AssetPickerSubViewController,
                                 UICollectionViewDataSource,
                                 UICollectionViewDelegate,
                                 PHPhotoLibraryChangeObserver,
                                 LVDVideoEditorControllerDelegate {

    public static let logger = Logger.log(AssetPreviewViewController.self, category: "LarkUIKit.ImagePicker.AssetPreviewViewController")

    // DATA
    private let phManager = PHCachingImageManager.default()
    private let album: Album
    private let defaultIndex: Int
    private let defaultIndexPreviewImage: UIImage?
    /// 选择视频时，是否支持点击"原图"按钮
    private let originVideo: Bool

    // UI
    private let cellMargin: CGFloat = 40
    private var collectionView: UICollectionView
    private var flowLayout: UICollectionViewFlowLayout
    private let topView = AssetPreviewTopView()
    private let bottomView: ImagePickerBottomView
    weak var toolBarDelegate: PhotoPickerBottomToolBarDelegate?
    var toolBar: PhotoPickerBottomToolBar?

    // LarkMedia
    private let mediaScene: MediaMutexScene = .imVideoPlay
    private let audioScenario = AudioSessionScenario("AssetBrowse", category: .playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])

    /// 是否支持视频编辑
    var supportVideoEditor: Bool = false

    private var currentShowIndex: Int {
        let index = Int(round(collectionView.contentOffset.x / collectionView.bounds.width))
        return max(0, min(index, album.assetsCount - 1))
    }

    private var lastCallbackIndex: Int?

    private let currentShowAssetLock = NSLock()

    private var currentShowAsset: PHAsset {
        currentShowAssetLock.lock()
        let asset = album.asset(at: currentShowIndex)
        currentShowAssetLock.unlock()
        return asset
    }

    private var isNaviBarHidden: Bool = false {
        didSet { if isNaviBarHidden != oldValue { changeNaviBarHidden(isNaviBarHidden) } }
    }

    private var toast: UDToast?
    private var videoExportSession: AVAssetExportSession?

    private lazy var iCloudImageDownloader = ICloudImageDownloader()

    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    override var prefersStatusBarHidden: Bool { return isNaviBarHidden }

    /// 开始手动滑动后，不再强制设置 contentOffset，防止抖动
    private var hasBeganDragging: Bool = false

    /// 初始化AssetBrowseViewController方法
    ///
    /// - Parameters:
    ///   - album: 要浏览的album
    ///   - index: ablum中默认展示的index
    ///   - previewImage: 默认展示的index对应的previewImage
    ///   - bottomViewConfig: bottomView配置信息
    init(album: Album, index: Int, previewImage: UIImage? = nil, originVideo: Bool, bottomViewConfig: ImagePickerBottomViewConfig) {
        self.album = album
        self.defaultIndex = index
        self.defaultIndexPreviewImage = previewImage
        self.originVideo = originVideo

        bottomView = ImagePickerBottomView(config: bottomViewConfig)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = UIApplication.shared.delegate?.window??.bounds.size ?? UIScreen.main.bounds.size
        layout.minimumLineSpacing = cellMargin
        self.flowLayout = layout
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)

        PHPhotoLibrary.shared().register(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // 此处兜底
        LarkMediaManager.shared.unlock(scene: mediaScene, options: .leaveScenarios)
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ud.staticBlack
        isNavigationBarHidden = true

        topView.delegate = self
        // If element is not found in the collection, returns nil.
        topView.selectIndex = selectedAssets.firstIndex(of: album.asset(at: defaultIndex))
        if (navigationController?.viewControllers.count ?? 0) == 1 {
            topView.style = .cancel
        } else {
            topView.style = .back
        }
        view.addSubview(topView)
        topView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.bottom.equalTo(viewTopConstraint).offset(44)
        }

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: cellMargin)
        collectionView.register(AssetPreviewImageCell.self, forCellWithReuseIdentifier: String(describing: AssetPreviewImageCell.self))
        collectionView.register(AssetPreviewVideoCell.self, forCellWithReuseIdentifier: String(describing: AssetPreviewVideoCell.self))
        collectionView.contentInsetAdjustmentBehavior = .never
        view.insertSubview(collectionView, belowSubview: topView)
        collectionView.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(cellMargin)
        }
        collectionView.backgroundColor = .clear

        bottomView.delegate = self
        bottomView.toolBarDelegate = toolBarDelegate
        bottomView.toolBar = toolBar
        view.addSubview(bottomView)
        bottomView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        _ = album.asset(at: defaultIndex)
        view.layoutIfNeeded()
        self.setupCollectionOffset()
        self.updateViewByShowAsset()
    }

    override func selectedAssetDidChange(_ selectedAssets: [PHAsset]) {
        super.selectedAssetDidChange(selectedAssets)
        bottomView.config.selectCount = selectedAssets.count
        delegate?.assetVCSelectDidChange(self)
    }

    override func isOriginalDidChange(_ isOriginal: Bool) {
        super.isOriginalDidChange(isOriginal)
        bottomView.config.originButtonSelected = isOriginal
    }

    private var preCurrentIndex: Int?
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard collectionView.bounds.width > 0 else { return }
        preCurrentIndex = currentShowIndex
        let size = view.bounds.size
        if size != self.flowLayout.itemSize {
            self.flowLayout.itemSize = size
            self.flowLayout.invalidateLayout()
            self.collectionView.reloadData()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let index = preCurrentIndex else { return }
        defer { preCurrentIndex = nil }
        if !hasBeganDragging {
            self.collectionView.scrollToItem(
                at: IndexPath(row: index, section: 0),
                at: .centeredHorizontally,
                animated: false
            )
        }
    }

    private func changeNaviBarHidden(_ isNaviBarHidden: Bool) {
        if isNaviBarHidden {
            topView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(view.snp.top)
                make.height.equalTo(topView.frame.height)
            }
            bottomView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalTo(view.snp.bottom)
                make.height.equalTo(bottomView.frame.height)
            }
        } else {
            topView.snp.remakeConstraints { (make) in
                make.left.top.right.equalToSuperview()
                make.bottom.equalTo(viewTopConstraint).offset(44)
            }
            bottomView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
        })
        self.setNeedsStatusBarAppearanceUpdate()
    }

    private func setupCollectionOffset() {
        let size = self.view.bounds.size
        if size != self.flowLayout.itemSize {
            self.flowLayout.itemSize = size
            self.flowLayout.invalidateLayout()
            self.collectionView.reloadData()
        }
        self.collectionView.scrollToItem(
            at: IndexPath(row: self.defaultIndex, section: 0),
            at: .centeredHorizontally,
            animated: false
        )
    }

    private func currentImage() -> UIImage? {
        let cell = collectionView.cellForItem(at: IndexPath(item: currentShowIndex, section: 0))
        if let cell = cell as? AssetPreviewVideoCell {
            return cell.currentImage
        } else if let cell = cell as? AssetPreviewImageCell {
            return cell.currentShowImage
        }
        return nil
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return album.assetsCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = album.asset(at: indexPath.row)
        if asset.mediaType == .video {
            let reuseID = String(describing: AssetPreviewVideoCell.self)
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseID, for: indexPath)
                as? AssetPreviewVideoCell else {
                return UICollectionViewCell()
            }
            cell.assetIdentifier = asset.localIdentifier
            cell.videoDidPlayToEnd = { [weak self] _ in
                guard let `self` = self else { return }
                self.isNaviBarHidden = false
                LarkMediaManager.shared.unlock(scene: self.mediaScene, options: .leaveScenarios)
            }
            if let editVideo = editVideoCache.editVideo(key: asset.localIdentifier) {
               let asset = AVURLAsset(url: editVideo)
                cell.setPlayerItem(AVPlayerItem(url: editVideo))
            } else {
                if indexPath.row == defaultIndex {
                    cell.setPreviewImage(defaultIndexPreviewImage)
                }

                let options = PHVideoRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                _ = try? AlbumEntry.requestPlayerItem(forToken: AssetBrowserToken.requestPlayerItem.token,
                                                      manager: phManager,
                                                      forVideoAsset: asset,
                                                      options: options) { (item, _) in
                    DispatchQueue.main.async {
                        if cell.assetIdentifier ?? "" == asset.localIdentifier {
                            cell.setPlayerItem(item)
                        }
                    }
                }
            }
            return cell
        } else {
            let reuseID = String(describing: AssetPreviewImageCell.self)
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseID, for: indexPath)
                as? AssetPreviewImageCell else {
                return UICollectionViewCell()
            }
            if indexPath.row == defaultIndex {
                cell.setImage(defaultIndexPreviewImage)
            }
            cell.assetIdentifier = asset.localIdentifier
            if let editImage = editImageCache.editImage(key: asset.localIdentifier) {
                cell.setImage(editImage)
            } else {
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true

                if asset.isGIF {
                    _ = try? AlbumEntry.requestImageData(forToken: AssetBrowserToken.requestImageData.token,
                                                         manager: phManager,
                                                         forAsset: asset,
                                                         options: options,
                                                         resultHandler: { imageData, _, _, _ in
                            if cell.assetIdentifier ?? "" == asset.localIdentifier {
                                if let data = imageData,
                                    let image = try? ByteImage(data) {
                                    cell.setImage(image)
                                }
                            }
                        }
                    )
                } else {
                    _ = try? AlbumEntry.requestImage(forToken: AssetBrowserToken.requestImage.token,
                                                     manager: phManager,
                                                     forAsset: asset,
                                                     targetSize: view.bounds.size * UIScreen.main.scale,
                                                     contentMode: .aspectFit,
                                                     options: options,
                                                     resultHandler: { (image, _) in

                        if cell.assetIdentifier ?? "" == asset.localIdentifier {
                            cell.setImage(image)
                        }})
                }
            }
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let videoCell = collectionView.cellForItem(at: IndexPath(item: currentShowIndex, section: 0)) as? AssetPreviewVideoCell {
            if videoCell.isPlaying {
                videoCell.stopPlaying()
                isNaviBarHidden = false
                LarkMediaManager.shared.unlock(scene: mediaScene, options: .leaveScenarios)
            } else {
                // 视频播放激活 audioSession
                LarkMediaManager.shared.tryLock(scene: mediaScene, options: .mixWithOthers, observer: self) { result in
                    switch result {
                    case .success(let resource):
                        resource.audioSession.enter(self.audioScenario)
                        DispatchQueue.main.async {
                            videoCell.startPlaying()
                            self.isNaviBarHidden = true
                        }
                    case .failure(let error):
                        Self.logger.error("PHAsset: get video play lock failed \(error)")
                        if case let MediaMutexError.occupiedByOther(context) = error, let msg = context.1 {
                            self.showMediaLockAlert(msg: msg)
                        }
                    }
                }
            }
        } else {
            isNaviBarHidden = !isNaviBarHidden
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? AssetPreviewImageCell)?.resetZoomView()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        hasBeganDragging = true
        if let cell = collectionView.cellForItem(at: IndexPath(row: currentShowIndex, section: 0)) as? AssetPreviewVideoCell {
            cell.stopPlaying()
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        hasBeganDragging = false
        if !decelerate {
            updateViewByShowAsset()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateViewByShowAsset()
    }

    private func updateViewByShowAsset() {
        // 根据在数组中的位置 是否刷新
        topView.selectIndex = selectedAssets.firstIndex(of: currentShowAsset)

        if currentShowAsset.mediaType == .video {
            bottomView.config.originButtonEnable = self.originVideo
            // 判断是否是主 scene
            var isMainScene = true
            if #available(iOS 13.0, *),
               Display.pad,
               let scene = self.currentScene(),
               !scene.sceneInfo.isMainScene() {
                isMainScene = false
            }
            // 判断是否开启视频编辑
            if LarkFeatureGating.shared.getFeatureBoolValue(for: "messenger.mobile.ve_camera"),
                self.supportVideoEditor,
                LVDCameraService.available(),
                isMainScene {
                bottomView.config.centerButtonHidden = false
            } else {
                bottomView.config.centerButtonHidden = true
            }
        } else if currentShowAsset.isGIF {
            bottomView.config.originButtonEnable = true
            bottomView.config.centerButtonHidden = true
        } else {
            bottomView.config.originButtonEnable = true
            bottomView.config.centerButtonHidden = false
        }
        let currentShowIndex = self.currentShowIndex
        if lastCallbackIndex != currentShowIndex { // TODO: 是否重复调用该方法
            lastCallbackIndex = currentShowIndex
            delegate?.assetVC(self, didPreview: currentShowAsset)
        }
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if let details = changeInstance.changeDetails(for: album.fetchResult) {
            let isEmpty = details.removedIndexes?.isEmpty ?? true
            if !isEmpty {
                DispatchQueue.main.async { [self] in
                    topViewBackButtonDidClick(topView)
                }
            }
        }
    }

    // iCloud
    func guardDownloadedFromiCloud(asset: PHAsset,
                                   finishCompletion: (() -> Void)? = nil,
                                   cancelCompletion: (() -> Void)? = nil) {
        guard asset.isInICloud else {
            finishCompletion?()
            return
        }
        let dismissToast = { [weak self] in
            self?.toast?.remove()
            self?.toast = nil
        }
        let requestID = iCloudImageDownloader.downloadAsset(with: asset, progressBlock: nil) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                dismissToast()
                switch result {
                case .success:
                    finishCompletion?()
                case .failure(let error):
                    cancelCompletion?()
                    ICloudImageDownloader.toastError(error, on: self.view)
                }
            }
        }
        self.toast = ICloudImageDownloader.showSyncLoadingToast(on: self.view, cancelCallback: { [weak self] in
            dismissToast()
            cancelCompletion?()
            if let requestID = requestID {
                self?.iCloudImageDownloader.cancel(requestID: requestID)
            }
        })
    }

    func editorTakeVideo(_ videoURL: URL, controller vc: UIViewController) {
        self.editVideoCache.addEditVideo(videoURL, key: self.currentShowAsset.localIdentifier)
        self.collectionView.reloadItems(at: [IndexPath(item: self.currentShowIndex, section: 0)])
        vc.dismiss(animated: false, completion: nil)
    }
}

extension AssetPreviewViewController: AssetPreviewTopViewDelegate {
    func topViewBackButtonDidClick(_ topView: AssetPreviewTopView) {
        switch topView.style {
        case .back:
            navigationController?.popViewController(animated: true)
        case .cancel:
            delegate?.assetVCCancelButtonDidClick(self)
        }
    }

    func topViewNumberButtonDidClick(_ topView: AssetPreviewTopView) {
        let currentAsset = currentShowAsset
        if topView.selectIndex != nil {
            deselectAsset(currentAsset)
            topView.selectIndex = nil
        // 如果为nil且可以选中
        } else if selectAsset(currentAsset, image: currentImage()) {
            topView.selectIndex = selectedAssets.firstIndex(of: currentAsset)
            guardDownloadedFromiCloud(asset: currentAsset, cancelCompletion: { [weak self] in
                self?.deselectAsset(currentAsset)
                self?.topView.selectIndex = nil
            })
        }
    }
}

extension AssetPreviewViewController: ImageEditViewControllerDelegate {
    func closeButtonDidClicked(vc: EditViewController) {
        vc.exit()
    }

    func finishButtonDidClicked(vc: EditViewController, editImage: UIImage) {
        self.editImageCache.addEditImage(editImage, key: self.currentShowAsset.localIdentifier)
        self.collectionView.reloadItems(at: [IndexPath(item: self.currentShowIndex, section: 0)])
        vc.exit()
    }
}

extension AssetPreviewViewController: ImagePickerBottomViewDelegate {
    func bottomViewOriginButtonDidClick(_ bottomView: ImagePickerBottomView) {
        delegate?.assetVCOriginButtonDidClick(self)
        setIsOriginal(!bottomView.config.originButtonSelected)
    }

    func bottomViewCenterButtonDidClick(_ bottomView: ImagePickerBottomView) {
        if let currentShowCell = collectionView.cellForItem(at: IndexPath(item: currentShowIndex, section: 0)) as? AssetPreviewImageCell,
           let currentShowImage = currentShowCell.currentShowImage {
            delegate?.assetVCCenterButtonDidClick(self, isImage: true)
            let imageEditVC = ImageEditorFactory.createEditor(with: currentShowImage)
            imageEditVC.delegate = self
            imageEditVC.editEventObservable.subscribe(onNext: { [weak self] (event) in
                (self?.navigationController as? ImagePickerViewController)?.imageEditAction?(event)
            }).disposed(by: disposeBag)
            let navigationVC = LkNavigationController(rootViewController: imageEditVC)
            navigationVC.modalPresentationStyle = .fullScreen
            Navigator.shared.present(navigationVC, from: self, animated: false)
        }

        if let currentShowCell = collectionView.cellForItem(at: IndexPath(item: currentShowIndex, section: 0)) as? AssetPreviewVideoCell {
            let item = currentShowCell.item
            let currentAsset = currentShowAsset
            guardDownloadedFromiCloud(asset: currentAsset, finishCompletion: { [weak self] in
                guard let self = self else { return }
                // 跳转编辑页面
                let goToVideoEditor = { [weak self] (assets: [AVURLAsset]) in
                    guard let self = self else { return }
                    LarkMediaManager.shared.tryLock(scene: self.mediaScene, options: .mixWithOthers, observer: self) { result in
                        switch result {
                        case .success:
                            DispatchQueue.main.async {
                                self.delegate?.assetVCCenterButtonDidClick(self, isImage: false)
                                let controller = LVDCameraService.videoEditorController(with: self, assets: assets, from: self)
                                controller.rx.deallocated.subscribe(onNext: { _ in
                                    LarkMediaManager.shared.unlock(scene: self.mediaScene, options: .leaveScenarios)
                                }).disposed(by: self.disposeBag)
                                controller.modalPresentationStyle = .fullScreen
                                self.present(controller, animated: true, completion: nil)
                            }
                        case .failure(let error):
                            Self.logger.error("PHAsset: get video play lock failed \(error)")
                            if case let MediaMutexError.occupiedByOther(context) = error, let msg = context.1 {
                                self.showMediaLockAlert(msg: msg)
                            }
                        }
                    }
                }
                // 重新拉取 avasset
                let refetchAVAsset = { [weak self] (currentAsset: PHAsset) in
                    guard let self = self else { return }
                    let options = PHVideoRequestOptions()
                    options.deliveryMode = .highQualityFormat
                    options.isNetworkAccessAllowed = true
                    _ = try? AlbumEntry.requestAVAsset(forToken: AssetBrowserToken.requestAVAsset.token,
                                                       manager: self.phManager,
                                                       forVideoAsset: currentAsset,
                                                       options: options,
                                                       resultHandler: { (avAsset, _, _) in
                        if let urlAsset = avAsset as? AVURLAsset {
                            goToVideoEditor([urlAsset])
                        } else if item?.asset is AVComposition {
                            // 如果是 AVComposition，视频导出后再跳转编辑页面
                            self.exportAsset(with: currentAsset) { (urlAsset) in
                                if let urlAsset = urlAsset {
                                    goToVideoEditor([urlAsset])
                                }
                            }
                        } else {
                            Self.logger.error("PHAsset: get video url failed \(avAsset)")
                        }
                    })
                }

                if let urlAsset = item?.asset as? AVURLAsset {
                    // 之前的视频可能为远端 url，需要重新拉取
                    if urlAsset.url.isLocal {
                        goToVideoEditor([urlAsset])
                    } else {
                        refetchAVAsset(currentAsset)
                    }
                } else if item?.asset is AVComposition {
                    // 如果是 AVComposition，视频导出后再跳转编辑页面
                    self.exportAsset(with: currentAsset) { (urlAsset) in
                        if let urlAsset = urlAsset {
                            goToVideoEditor([urlAsset])
                        }
                    }
                } else if item == nil {
                    refetchAVAsset(currentAsset)
                } else {
                    assertionFailure("item asset is unsupport type")
                }
            }, cancelCompletion: nil)
        }
    }

    private func showMediaLockAlert(msg: String) {
        Self.execInMainThread {
            guard let window = self.view.window else {
                Self.logger.error("cannot find vc")
                return
            }
            let dialog = UDDialog()
            dialog.setContent(text: msg)
            dialog.addPrimaryButton(text: BundleI18n.LarkAssetsBrowser.Lark_Legacy_Sure)
            self.present(dialog, animated: true)
        }
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

    func bottomViewSendButtonDidClick(_ bottomView: ImagePickerBottomView) {
        if selectedAssets.isEmpty {
            let currentAsset = currentShowAsset
            guardDownloadedFromiCloud(asset: currentAsset, finishCompletion: { [weak self] in
                guard let self = self else { return }
                self.selectAsset(currentAsset, image: self.currentImage())
                self.finishSelect()
            })
        } else {
            finishSelect()
        }
    }

    func exportAsset(with asset: PHAsset, finishCallback: @escaping (AVURLAsset?) -> Void) {
        let tempAssetName = "videoExport-\(asset.localIdentifier.md5())-\(asset.modificationDate?.timeIntervalSince1970 ?? 0).mov"
        let tempFilePath = IsoPath.temporary() + tempAssetName
        // 检查是否已经存在导出的视频
        if tempFilePath.exists {
            finishCallback(AVURLAsset(url: tempFilePath.url))
            return
        }

        let dismissBlock = { [weak self] in
            self?.toast?.remove()
            self?.toast = nil
        }

        self.toast = self.showExportLoadingToast(on: self.view, cancelCallback: { [weak self] in
            dismissBlock()
            self?.videoExportSession?.cancelExport()
        })
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        let manager = PHImageManager.default()

        try? AlbumEntry.requestExportSession(forToken: AssetBrowserToken.requestExportSession.token,
                                             manager: manager,
                                             forVideoAsset: asset,
                                             options: options, exportPreset: AVAssetExportPresetPassthrough) { [weak self] (exportSession, _) in
            guard let `self` = self, let exportSession = exportSession else {
                dismissBlock()
                return
            }
            self.videoExportSession = exportSession
            exportSession.outputURL = tempFilePath.url
            exportSession.outputFileType = .mov
            exportSession.exportAsynchronously(completionHandler: {
                dismissBlock()
                switch exportSession.status {
                case .completed:
                    finishCallback(AVURLAsset(url: tempFilePath.url))
                case .cancelled:
                    Self.logger.error("PHAsset: export video user cancel error")
                    finishCallback(nil)
                default:
                    if tempFilePath.exists {
                        finishCallback(AVURLAsset(url: tempFilePath.url))
                    } else {
                        Self.logger.error("PHAsset: export video data error \(exportSession.status.rawValue) error \(exportSession.error)")
                        finishCallback(nil)
                    }
                }
            })
        }
    }

    @discardableResult
    func showExportLoadingToast(on viewToBeDisabled: UIView, cancelCallback: (() -> Void)? = nil) -> UDToast {
       return UDToast.showToast(
        with: .init(toastType: .loading,
                    text: BundleI18n.LarkAssetsBrowser.Lark_Legacy_VideoMessagePrepareToSend,
                    operation: .init(text: BundleI18n.LarkAssetsBrowser.Lark_Legacy_Cancel)),
        on: viewToBeDisabled,
        delay: 100_000,
        disableUserInteraction: true,
        operationCallBack: { _ in
            cancelCallback?()
        })
   }
}

extension AssetPreviewViewController: MediaResourceInterruptionObserver {
    func mediaResourceWasInterrupted(by scene: LarkMedia.MediaMutexScene, type: LarkMedia.MediaMutexType, msg: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            Self.logger.warn("interrupted by \(scene) \(type)")
        }
    }

    func mediaResourceInterruptionEnd(from scene: LarkMedia.MediaMutexScene, type: LarkMedia.MediaMutexType) {}
}
