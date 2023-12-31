//
//  AssetPickerSubViewController.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/9/3.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import Photos
import RxSwift
import LarkExtensions
import LarkUIKit
import UniverseDesignToast
import UniverseDesignDialog

protocol AssetPickerSubViewControllerDelegate: AnyObject {
    func assetVCOriginButtonDidClick(_ assetVC: AssetPickerSubViewController)
    func assetVCCancelButtonDidClick(_ assetVC: AssetPickerSubViewController)
    func assetVCSendButtonDidClick(_ assetVC: AssetPickerSubViewController)
    func assetVCCenterButtonDidClick(_ assetVC: AssetPickerSubViewController, isImage: Bool)
    func assetVCSelectDidChange(_ assetVC: AssetPickerSubViewController)
    func assetVC(_ assetVC: AssetPickerSubViewController, didFinishPicture image: UIImage)
    func assetVC(_ assetVC: AssetPickerSubViewController, didPreview asset: PHAsset)
}

class AssetPickerSubViewController: BaseUIViewController {
    
    weak var delegate: AssetPickerSubViewControllerDelegate?

    let disposeBag = DisposeBag()

    private var imagePickerVC: ImagePickerViewController {
        return (navigationController as? ImagePickerViewController) ?? ImagePickerViewController()
    }

    /// 当前选择PHAsset的类型
    var assetType: ImagePickerAssetType {
        return imagePickerVC.assetType
    }

    /// 当前选中的asset数组
    var selectedAssets: [PHAsset] {
        return imagePickerVC.selectedAssetsSubject.value
    }

    /// 选中的Images
    var selectedImages: [PHAsset] {
        return selectedAssets.filter { $0.mediaType == .image }
    }

    /// 选中的videos
    var selectedVideos: [PHAsset] {
        return selectedAssets.filter { $0.mediaType == .video }
    }

    /// 最多可以选择的image数量
    var imageMaxCount: Int {
        switch assetType {
        case .imageOnly(maxCount: let imageMaxCount):
            return imageMaxCount
        case .imageAndVideo(imageMaxCount: let imageMaxCount, _):
            return imageMaxCount
        case .imageOrVideo(imageMaxCount: let imageMaxCount, _):
            return imageMaxCount
        case .imageAndVideoWithTotalCount(totalCount: let totalCount):
            return totalCount
        case .videoOnly:
            return 0
        }
    }

    /// 最多可以选择的video数量
    var videoMaxCount: Int {
        switch assetType {
        case .videoOnly(maxCount: let videoMaxCount):
            return videoMaxCount
        case .imageAndVideo(imageMaxCount: _, let videoMaxCount):
            return videoMaxCount
        case .imageOrVideo(imageMaxCount: _, let videoMaxCount):
            return videoMaxCount
        case .imageAndVideoWithTotalCount(totalCount: let totalCount):
            return totalCount
        case .imageOnly:
            return 0
        }
    }
    var reachMaxCountTipBlock: ((PhotoPickerSelectDisableType) -> String?)?

    /// 选择的image是否已经达到最大数目
    var isImageReachMax: Bool { return selectedImages.count == imageMaxCount }

    /// 选择的video是否已经达到最大数目
    var isVideoReachMax: Bool { return selectedVideos.count == videoMaxCount }

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePickerVC.selectedAssetsSubject
            .asObservable()
            .subscribe(onNext: { [weak self] (selectedAssets) in
                self?.selectedAssetDidChange(selectedAssets)
            })
            .disposed(by: disposeBag)

        imagePickerVC.isOriginalSubject
            .asObservable()
            .subscribe(onNext: { [weak self] (isOriginal) in
                self?.isOriginalDidChange(isOriginal)
            })
            .disposed(by: disposeBag)
    }

    var imageCache: ImageCache {
        return imagePickerVC.imageCache
    }

    var editImageCache: EditImageCache {
        return imagePickerVC.editImageCache
    }

    var editVideoCache: EditVideoCache {
        return imagePickerVC.editVideoCache
    }

    @objc
    func cancelItemDidTap() {
        delegate?.assetVCCancelButtonDidClick(self)
    }

    func finishSelect() {
        delegate?.assetVCSendButtonDidClick(self)
    }

    func selectChange() {
        delegate?.assetVCSelectDidChange(self)
    }

    /// 添加一个asset为选中
    ///
    /// - Parameter asset: 要选择的asset
    /// - Returns: asset是否添加成功（达到最大数目或者混选，则返回false）
    @discardableResult
    func selectAsset(_ asset: PHAsset, image: UIImage?) -> Bool {
        switch assetType {
        case .imageOnly:
            guard asset.mediaType == .image else { showCanNotMixTypeAlert(); return false }
        case .videoOnly:
            guard asset.mediaType == .video else { showCanNotMixTypeAlert(); return false }
        case .imageOrVideo:
            if let firstAsset = self.selectedAssets.first, firstAsset.mediaType != asset.mediaType {
                showCanNotMixTypeAlert()
                return false
            }
        case .imageAndVideo, .imageAndVideoWithTotalCount:
            break
        }
        var selectedAssets = imagePickerVC.selectedAssetsSubject.value
        selectedAssets.lf_appendIfNotContains(asset)
        let selectedImages = selectedAssets.filter { $0.mediaType == .image }
        let selectedVideos = selectedAssets.filter { $0.mediaType == .video }

        if case let .imageAndVideoWithTotalCount(totalCount) = assetType, selectedAssets.count > totalCount {
            showCanNotSelectMoreAssetsAlert(count: totalCount)
            return false
        } else {
            if selectedImages.count > imageMaxCount {
                showCanNotSelectImageAlert()
                return false
            } else if selectedVideos.count > videoMaxCount {
                showCanNotSelectVideoAlert()
                return false
            } else {
                imageCache.addAsset(asset: asset, image: image)
                imagePickerVC.selectedAssetsSubject.accept(selectedAssets)
                return true
            }
        }
    }

    /// 取消选择一个asset
    ///
    /// - Parameter asset: 要取消的asset
    /// - Returns: 是否取消成功（如果需要取消的asset不在原来的数组中，则返回false）
    @discardableResult
    func deselectAsset(_ asset: PHAsset) -> Bool {
        var selectedAssets = imagePickerVC.selectedAssetsSubject.value
        if selectedAssets.contains(asset) {
            selectedAssets.lf_remove(object: asset)
            imageCache.removeAsset(asset)
            imagePickerVC.selectedAssetsSubject.accept(selectedAssets)
            return true
        }
        return false
    }

    @discardableResult
    func deselectAllAssets() -> Bool {
        if !imagePickerVC.selectedAssetsSubject.value.isEmpty {
            imageCache.removeAll()
            imagePickerVC.selectedAssetsSubject.accept([])
            return true
        }
        return false
    }

    /// 选中图片变化回调
    func selectedAssetDidChange(_ selectedAssets: [PHAsset]) {
        // 应该子类重写
    }

    /// 设置是否是原图
    func setIsOriginal(_ isOriginal: Bool) {
        imagePickerVC.isOriginalSubject.accept(isOriginal)
    }

    /// 原图按钮变化回调
    func isOriginalDidChange(_ isOriginal: Bool) {
        // 应该子类重写
    }

    /// 开始预览回调
    func didPreview(asset: PHAsset) {
        delegate?.assetVC(self, didPreview: asset)
    }

    /// 不能混选图片，视频弹框
    private func showCanNotMixTypeAlert() {
        guard let window = self.view.window else { return }
        let tip = reachMaxCountTipBlock?(.cannotMix)
        UDToast.showTips(with: tip ?? BundleI18n.LarkAssetsBrowser.Lark_Legacy_SelectPhotosOrVideosError,
                         on: window)
    }

    /// 超出选择最大图片限制弹框
    private func showCanNotSelectImageAlert() {
        guard let window = self.view.window else { return }
        let tip = reachMaxCountTipBlock?(.maxImageCount(selectedImages.count))
        let text = tip ?? String(format: BundleI18n.LarkAssetsBrowser.Lark_Legacy_MaxImageLimitReachedMessage,
                          selectedImages.count)
        UDToast.showFailure(with: text, on: window)
    }

    /// 超出选择最大图片限制弹框
    private func showCanNotSelectMoreAssetsAlert(count: Int) {
        guard let window = self.view.window else { return }
        let tip = reachMaxCountTipBlock?(.maxImageCount(count))
        let text = tip ?? BundleI18n.LarkAssetsBrowser.Lark_Legacy_Max9Items(count)
        UDToast.showFailure(with: text, on: window)
    }

    /// 超出选择最大视频限制弹框
    private func showCanNotSelectVideoAlert() {
        guard let window = self.view.window else { return }
        let tip = reachMaxCountTipBlock?(.maxVideoCount(selectedVideos.count))
        let text = tip ?? String(format: BundleI18n.LarkAssetsBrowser.Lark_Legacy_MaxVideoLimitReachedMessage,
                          selectedVideos.count)
        UDToast.showFailure(with: text, on: window)
    }
}
