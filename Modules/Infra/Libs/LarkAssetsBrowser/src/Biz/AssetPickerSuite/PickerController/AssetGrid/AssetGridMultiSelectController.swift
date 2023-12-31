//
//  AssetGridMultiSelectController.swift
//  LarkImagePicker
//
//  Created by ChalrieSu on 2018/8/28.
//  Copyright © 2018 ChalrieSu. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Photos
import LarkContainer
import LarkSetting
import LarkSensitivityControl
import LarkVideoDirector
import LKCommonsLogging
import LarkUIKit
import PhotosUI
import ByteWebImage
import UniverseDesignToast

final class AssetGridMultiSelectController: AssetGridBaseViewController {
    private let bottomView: ImagePickerBottomView
    weak var toolBarDelegate: PhotoPickerBottomToolBarDelegate?

    // 从 AssetPickerSuiteView 一层层传进来的，目的是为了让 PickerView 和 PickerController 联动
    var toolBar: PhotoPickerBottomToolBar?

    private var takePhotoButton: LKBarButtonItem?
    private let hasTakePhotoButton: Bool
    private var toast: UDToast?
    public static let logger = Logger.log(AssetGridMultiSelectController.self,category:"LarkUIKit.ImagePicker.AssetGridMultiSelectController+iCloud")
    private lazy var iCloudImageDownloader = ICloudImageDownloader()
    /// 选择视频时，是否支持点击"原图"按钮
    private let originVideo: Bool
    /// 是否支持视频编辑
    var supportVideoEditor: Bool = false
    init(dataCenter: AlbumListDataCenter, originVideo: Bool, bottomViewConfig: ImagePickerBottomViewConfig, takePhotoEnable: Bool) {
        self.originVideo = originVideo
        self.bottomView = ImagePickerBottomView(config: bottomViewConfig)
        self.hasTakePhotoButton = takePhotoEnable
        super.init(dataCenter: dataCenter)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if hasTakePhotoButton {
            let pictrueItem = LKBarButtonItem(image: nil, title: BundleI18n.LarkAssetsBrowser.Lark_Docs_ImagePickerCamera)
            pictrueItem.button.addTarget(self, action: #selector(pictrueItemDidTap), for: .touchUpInside)
            pictrueItem.setBtnColor(color: .red)
            self.navigationItem.rightBarButtonItem = pictrueItem
            self.takePhotoButton = pictrueItem
            setCameraButtonEnabled()
        }

        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(bottomView)
        collectionView.snp.remakeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(bottomView.snp.top)
        }

        bottomView.delegate = self
        bottomView.toolBarDelegate = toolBarDelegate
        bottomView.toolBar = toolBar

        bottomView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        // 界面显示后应该主动更新一次"原图"按钮的有效性
        customOriginalButtonEnable()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }

    private func setCameraButtonEnabled() {
        let isEnabled = selectedAssets.count < assetType.maxCount
        takePhotoButton?.isEnabled = isEnabled
        takePhotoButton?.setBtnColor(color: isEnabled ? UIColor.ud.primaryContentDefault : UIColor.ud.textLinkDisabled)
    }

    @objc
    private func pictrueItemDidTap() {
        let userResolver = Container.shared.getCurrentUserResolver()
        LarkCameraKit.takePhoto(from: self, userResolver: userResolver) { [weak self] image, _ in
            guard let self else { return }
            self.delegate?.assetVC(self, didFinishPicture: image)
            self.dismiss(animated: true)
        }
    }

    override func selectedAssetDidChange(_ selectedAssets: [PHAsset]) {
        super.selectedAssetDidChange(selectedAssets)
        self.delegate?.assetVCSelectDidChange(self)
        bottomView.config.sendButtonEnable = !selectedAssets.isEmpty
        bottomView.config.centerButtonHidden = selectedAssets.isEmpty
        bottomView.config.selectCount = selectedAssets.count
        setCameraButtonEnabled()
    }

    override func isOriginalDidChange(_ isOriginal: Bool) {
        super.isOriginalDidChange(isOriginal)
        bottomView.config.originButtonSelected = isOriginal
        self.delegate?.assetVCSelectDidChange(self)
    }

    override func onExit() {
        super.onExit()
        iCloudImageDownloader.cancelAll()
    }

    /// 显示AssetBrowseVC, 从预览进来albumAndIndex为nil，直接点击图片进来albumAndIndex应该不为空
    private func pushAssetBrowseVC(withAlbumAndIndex albumAndIndex: (Album, Int)?, selectedAssets: [PHAsset]) {
        var config = bottomView.config
        config.style = .dark
        config.centerButtonTitle = BundleI18n.LarkAssetsBrowser.Lark_Legacy_Edit
        config.centerButtonHidden = false // 图片查看页面，中间始终展示编辑按钮
        config.sendButtonEnable = true // 图片查看页面，发送按钮一直可用

        let album: Album
        let index: Int
        var previewImage: UIImage?
        if let albumAndIndex = albumAndIndex {
            album = albumAndIndex.0
            index = albumAndIndex.1
            previewImage = (collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? AssetGridCell)?.currentImage
        } else {
            let collection = PHAssetCollection.transientAssetCollection(with: selectedAssets, title: nil)
            let fetchResult = PHAsset.fetchAssets(in: collection, options: nil)
            album = Album(collection: collection, fetchResult: fetchResult)
            index = 0
        }
        let assetBroseViewController = AssetPreviewViewController(album: album,
                                                                 index: index,
                                                                 previewImage: previewImage,
                                                                 originVideo: self.originVideo,
                                                                 bottomViewConfig: config)
        assetBroseViewController.delegate = self.delegate
        assetBroseViewController.toolBar = self.toolBar
        assetBroseViewController.toolBarDelegate = self.toolBarDelegate
        assetBroseViewController.reachMaxCountTipBlock = self.reachMaxCountTipBlock
        assetBroseViewController.supportVideoEditor = self.supportVideoEditor
        navigationController?.pushViewController(assetBroseViewController, animated: true)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == currentAlbum.assetsCount && PhotoPickView.preventStyle == .limited {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SelectMoreCell.identifier, for: indexPath) as? SelectMoreCell else {
                return UICollectionViewCell()
            }
            return cell
        }
        let reuseID = String(describing: AssetGridCell.self)
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseID, for: indexPath) as? AssetGridCell else {
            return UICollectionViewCell()
        }
        let asset = currentAlbum.asset(at: indexPath.item)
        cell.currentAsset = asset
        // 倒序设置
        let index = currentAlbum.assetsCount - indexPath.item - 1
        cell.accessibilityIdentifier = "lark.uikit.assetgridcell.\(index)"
        cell.checkBoxIdentifier = "lark.uikit.assetgridcell.checkbox.\(index)"
        cell.videoDuration = asset.duration
        cell.numberButtonDidClickBlock = { [weak self] (cell) in
            self?.assetGridCell(cell, didClickWithAsset: asset)
        }
        if let editImage = editImageCache.editImage(key: asset.localIdentifier) {
            cell.setImage(editImage)
            if let key = self.disposedKey {
                AssetsPickerTracker.end(key: key)
                self.disposedKey = nil
            }
        } else if let editVideo = editVideoCache.editVideo(key: asset.localIdentifier) {
            let cellSize = calculateItemSize(containerSize: view.bounds.size)
            let targetSize = CGSize(width: cellSize.width * UIScreen.main.scale, height: cellSize.height * UIScreen.main.scale)
            let asset = AVURLAsset(url: editVideo)
            let generator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = targetSize
            if let cgimage = try? generator.copyCGImage(at: CMTimeMake(value: 0, timescale: 10), actualTime: nil) {
                cell.setImage(UIImage(cgImage: cgimage))
            }
            if let key = self.disposedKey {
                AssetsPickerTracker.end(key: key)
                self.disposedKey = nil
            }
        } else {
            let cellSize = calculateItemSize(containerSize: view.bounds.size)
            let targetSize = CGSize(width: cellSize.width * UIScreen.main.scale, height: cellSize.height * UIScreen.main.scale)
            _ = try? AlbumEntry.requestImage(forToken: AssetBrowserToken.requestImage.token,
                                             manager: imageManager,
                                             forAsset: asset,
                                             targetSize: targetSize,
                                             contentMode: .aspectFill,
                                             options: nil) { (image, _) in
                if cell.assetIdentifier ?? "" == asset.localIdentifier {
                    if image != nil {
                        cell.setImage(image)
                    }
                    if let key = self.disposedKey {
                        AssetsPickerTracker.end(key: key)
                        self.disposedKey = nil
                    }
                }
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? AssetGridCell {
            updateDisableMaskForCell(cell, at: indexPath)
        }
    }

    private func updateDisableMaskForCell(_ cell: AssetGridCell, at indexPath: IndexPath? = nil) {
        guard let asset = cell.currentAsset else { return }
        cell.selectIndex = selectedAssets.firstIndex(of: asset)
        let isSameType = shouldShowMask(asset: asset)
        if cell.selectIndex == nil {
            switch assetType {
            case .imageOnly:
                cell.showMask = isImageReachMax || !isSameType
            case .videoOnly:
                cell.showMask = isVideoReachMax || !isSameType
            case .imageOrVideo:
                cell.showMask = isImageReachMax || isVideoReachMax || !isSameType
            case .imageAndVideo:
                if asset.mediaType == .video, isVideoReachMax {
                    cell.showMask = true
                } else if asset.mediaType == .image, isImageReachMax {
                    cell.showMask = true
                } else {
                    cell.showMask = false
                }
            case .imageAndVideoWithTotalCount(totalCount: let count):
                cell.showMask = selectedAssets.count >= count
            }
        } else {
            cell.showMask = false
        }
    }

    private func assetGridCell(_ cell: AssetGridCell, didClickWithAsset asset: PHAsset) {
        // 当前cell未选中状态，需要添加
        if cell.selectIndex == nil {
            if selectAsset(asset, image: cell.currentImage) {

                cell.selectIndex = selectedAssets.firstIndex(of: asset)
                /// 在reload之前先保存 indexPath，以便后续对该 cell 进行操作
                let indexPath = collectionView.indexPath(for: cell)
                if asset.isInICloud {
                    downloadAssetFromICloud(indexPath: indexPath, asset: asset)
                }
                cell.numberBox.startTapBounceAnimation()
            }

        } else {
            // 当前cell为选中状态 需要移除选中状态 刷新数字
            cell.selectIndex = nil
            deselectAsset(asset)
            // 删除一个元素之后 需要对相关的cell的值重写设定
            reloadIndexForSelectedAssets()
        }

        updateVisibleCellMaskView()
        customOriginalButtonEnable()
    }

    func customOriginalButtonEnable() {
        if let lastAsset = selectedAssets.last {
            switch assetType {
            case .imageOrVideo, .videoOnly:
                if lastAsset.mediaType == .video {
                    bottomView.config.originButtonEnable = self.originVideo
                } else {
                    bottomView.config.originButtonEnable = true
                }
            case .imageOnly, .imageAndVideo, .imageAndVideoWithTotalCount:
                bottomView.config.originButtonEnable = true
            }
        }
    }

    func updateVisibleCellMaskView() {
        for cell in collectionView.visibleCells.compactMap({ $0 as? AssetGridCell }) {
            if let asset = cell.currentAsset, cell.selectIndex == nil {
                updateDisableMaskForCell(cell)
            }
        }
    }

    private func reloadIndexForSelectedAssets() {
        for i in 0 ..< selectedAssets.count {
            let asset = selectedAssets[i]
            let indexPath = IndexPath(item: currentAlbum.index(of: asset), section: 0)
            let cell = self.collectionView.cellForItem(at: indexPath) as? AssetGridCell
            if let cell = cell {
                cell.selectIndex = i
            }
        }
    }

    private func shouldShowMask(asset: PHAsset?) -> Bool {
        var isSameType = true
        if let first = selectedAssets.first,
           first.mediaType != asset?.mediaType {
            isSameType = false
        }
        return isSameType
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == currentAlbum.assetsCount && PhotoPickView.preventStyle == .limited {
            if #available(iOS 14, *) {
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
            }
        } else {
            pushAssetBrowseVC(withAlbumAndIndex: (currentAlbum, indexPath.item), selectedAssets: selectedAssets)
        }
    }
}

extension AssetGridMultiSelectController: ImagePickerBottomViewDelegate {
    func bottomViewOriginButtonDidClick(_ bottomView: ImagePickerBottomView) {
        setIsOriginal(!bottomView.config.originButtonSelected)
    }

    func bottomViewCenterButtonDidClick(_ bottomView: ImagePickerBottomView) {
        pushAssetBrowseVC(withAlbumAndIndex: nil, selectedAssets: selectedAssets)
    }

    func bottomViewSendButtonDidClick(_ bottomView: ImagePickerBottomView) {
        finishSelect()
    }
}

// MARK: - iCloud相关
extension AssetGridMultiSelectController {

    private func downloadAssetFromICloud(indexPath: IndexPath?, asset: PHAsset) {
        self.toast = ICloudImageDownloader.showSyncLoadingToast(on: self.view, cancelCallback: { [weak self] in
            self?.removeSyncLoadingHud()
            self?.cancelSeleceting(indexPath: indexPath, asset: asset)
        })
        iCloudImageDownloader.downloadAsset(with: asset, progressBlock: nil) { [weak self] (result) in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self?.removeSyncLoadingHud()
                    AssetGridMultiSelectController.logger.info("Download asset from iCloud success!")
                }
                return
            case .failure(let error):
                /// Avoid repainting collectionView too often after download failure
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    guard let self = self else { return }
                    self.removeSyncLoadingHud()
                    self.cancelSeleceting(indexPath: indexPath, asset: asset)
                    ICloudImageDownloader.toastError(error, on: self.view)
                }
            }
        }
    }

    private func cancelSeleceting(indexPath: IndexPath?, asset: PHAsset) {
        guard let indexPath = indexPath,
              let cell = self.collectionView.cellForItem(at: indexPath) as? AssetGridCell else {
                  AssetGridMultiSelectController.logger.info("Get cell from indexPath failed")
                  return
        }
        cell.selectIndex = nil
        self.deselectAsset(asset)
        self.reloadIndexForSelectedAssets()

    }

    private func removeSyncLoadingHud() {
        self.toast?.remove()
        self.toast = nil
    }
}
