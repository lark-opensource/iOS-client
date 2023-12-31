//
//  PhotoPickView.swift
//  LarkUIKit
//
//  Created by zc09v on 2017/6/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Photos
import LarkButton
import LarkUIKit
import UniverseDesignToast

public protocol PhotoPickViewDelegate: AnyObject {
    func takePhoto()
    func clickOriginButton()
    func showPhotoLibrary(selectedItems: [PHAsset], useOriginal: Bool)
    func pickedImages(images: [PHAsset], useOriginal: Bool)
    func pickedImagesChange(images: [PHAsset], useOriginal: Bool)
    func preview(asset: PHAsset, selectedImages: [PHAsset], useOriginal: Bool)
    func preview(selectedItems: [PHAsset], useOriginal: Bool)
    func goSetting()
    func shouldReload()
    func photoPickerReload(with assetResult: PHFetchResult<PHAsset>)
}

public enum PhotoPickerAssetType {
    /// 只能选择图片
    case imageOnly(maxCount: Int)
    /// 只能选择视频
    case videoOnly(maxCount: Int)
    /// 只能选择图片或者视频
    case imageOrVideo(imageMaxCount: Int, videoMaxCount: Int)
    /// 可以选择图片加视频，分别都有数量限制
    case imageAndVideo(imageMaxCount: Int, videoMaxCount: Int)
    /// 可以选择图片加视频，有总数限制
    case imageAndVideoWithTotalCount(totalCount: Int)

    public static var `default`: PhotoPickerAssetType {
        return .imageOrVideo(imageMaxCount: 9, videoMaxCount: 1)
    }
}

public final class PhotoPickView: UIView {
    public weak var delegate: PhotoPickViewDelegate?
    public var reachMaxCountTipBlock: ((PhotoPickerSelectDisableType) -> String?)?
    private let imageCache: ImageCache

    private let photoScrollPicker: PhotoScrollPicker
    let bottomToolBar: PhotoPickerBottomToolBar
    private var tipsView: PhotoPickerTipsView
    private var photoPermissionStatus: PHAuthorizationStatus

    var fromMoment: Bool = false {
        didSet {
            photoScrollPicker.fromMoment = fromMoment
        }
    }

    public var bottomOffset: CGFloat = Display.iPhoneXSeries ? -32 : 0 {
        didSet {
            bottomToolBar.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview().offset(self.bottomOffset)
            }
        }
    }

    public static var preventStyle: PreventStyle {
        var style: PreventStyle = .none
        if #available(iOS 14, *) {
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            if status == .limited {
                style = .limited
            } else if status == .denied {
                style = .denied
            }
        } else {
            let status = PHPhotoLibrary.authorizationStatus()
            if status == .denied {
                style = .denied
            }
        }
        return style
    }

    public init(assetType: PhotoPickerAssetType,
                originVideo: Bool,
                isOriginalButtonHidden: Bool,
                sendButtonTitle: String,
                imageCache: ImageCache = ImageCache(),
                editImage: @escaping (String) -> UIImage?,
                editVideo: @escaping (String) -> URL?) {
        self.photoScrollPicker = PhotoScrollPicker(assetType: assetType,
                                                   originVideo: originVideo,
                                                   imageCache: imageCache,
                                                   editImage: editImage,
                                                   editVideo: editVideo)
        self.bottomToolBar = PhotoPickerBottomToolBar(isOriginalButtonHidden: isOriginalButtonHidden,
                                                      sendButtonTitle: sendButtonTitle)
        self.tipsView = PhotoPickerTipsView()
        self.imageCache = imageCache

        if #available(iOS 14, *) {
            self.photoPermissionStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            self.photoPermissionStatus = PHPhotoLibrary.authorizationStatus()
        }
        super.init(frame: .zero)

        self.backgroundColor = UIColor.ud.N00

        tipsView.delegate = self
        addSubview(tipsView)
        tipsView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(44)
        }

        photoScrollPicker.cellSupportPanGesture = false
        photoScrollPicker.supportPreviewImage = true
        photoScrollPicker.selectedItemsDidChange = { [weak self] (selectedItems) in
            self?.bottomToolBar.set(selectCount: selectedItems.count)
        }
        photoScrollPicker.delegate = self
        self.addSubview(photoScrollPicker)
        photoScrollPicker.snp.makeConstraints { (make) in
            make.top.equalTo(tipsView.snp.bottom)
            make.right.equalToSuperview()
            make.height.equalTo(192).priority(.low)
        }

        bottomToolBar.delegate = self
        self.addSubview(bottomToolBar)
        bottomToolBar.snp.makeConstraints { (make) in
            make.top.equalTo(photoScrollPicker.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(44)
            make.bottom.equalToSuperview().offset(self.bottomOffset)
        }

        let leftToolBar = PhotoPickerLeftToolBar()
        leftToolBar.delegate = self
        self.addSubview(leftToolBar)
        leftToolBar.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.width.equalTo(58)
            make.height.equalTo(photoScrollPicker.snp.height)
            make.top.equalTo(tipsView.snp.bottom)
            make.right.equalTo(photoScrollPicker.snp.left)
        }
    }

    public func update(height: CGFloat) {
        photoScrollPicker.snp.remakeConstraints { (make) in
            make.top.equalTo(tipsView.snp.bottom)
            make.right.equalToSuperview()
            make.bottom.equalTo(bottomToolBar.snp.top)
            make.height.equalTo(height - bottomToolBar.bounds.height).priority(.low)
        }

        if photoScrollPicker.showCount > 0 {
            photoScrollPicker.layoutIfNeeded()
            photoScrollPicker.clearSizeCache()
            photoScrollPicker.reloadCollection()
        }
    }

    public func show() {
        self.showTipsView()
        self.photoScrollPicker.show { [weak self] status in
            if let oldStatus = self?.photoPermissionStatus, oldStatus != status {
                self?.photoPermissionStatus = status
                self?.delegate?.shouldReload()
                self?.showTipsView()
            }
        }
    }

    public func reload() {
        self.photoScrollPicker.reloadCollection()
    }

    public func setSelected(items: [PHAsset], useOriginal: Bool) {
        photoScrollPicker.selectedItems = items
        photoScrollPicker.updateSelectedItemsStatus()
        photoScrollPicker.reloadCollection()
        bottomToolBar.set(selectCount: items.count)
    }

    public func clear() {
        photoScrollPicker.clearSelectItems()
        photoScrollPicker.reloadCollection()
        bottomToolBar.set(isOrigin: false)
        bottomToolBar.set(selectCount: 0)
    }

    public func updateAssetType(_ type: PhotoPickerAssetType) {
        photoScrollPicker.assetType = type
        photoScrollPicker.reloadAssets()
    }

    private func showTipsView() {
        tipsView.snp.updateConstraints { (make) in
            make.height.equalTo(PhotoPickView.preventStyle.showTips() ? 44 : 0)
        }
        tipsView.isHidden = !PhotoPickView.preventStyle.showTips()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PhotoPickView: PhotoPickerLeftToolBarDelegate {
    func leftToolBarDidClickTakePhotoButton(_ leftToolBar: PhotoPickerLeftToolBar) {
        delegate?.takePhoto()
    }

    func leftToolBarDidClickShowPhotoLibraryButton(_ leftToolBar: PhotoPickerLeftToolBar) {
        let items = photoScrollPicker.selectedItems
        let useOriginal = bottomToolBar.isOriginal()
        delegate?.showPhotoLibrary(selectedItems: items,
                                   useOriginal: useOriginal)
    }
}

extension PhotoPickView: PhotoPickerBottomToolBarDelegate {
    func bottomToolBarDidClickOriginButton(_ bottomToolBar: PhotoPickerBottomToolBar) {
        bottomToolBar.set(isOrigin: !bottomToolBar.isOriginal())
        delegate?.clickOriginButton()
        // 选中\取消原图也认为图片选择有变化
        var selectedItems = photoScrollPicker.selectedItems
        if !selectedItems.isEmpty {
            delegate?.pickedImagesChange(images: selectedItems, useOriginal: bottomToolBar.isOriginal())
        }
    }

    func bottomToolBarDidClickPreviewButton(_ bottomToolBar: PhotoPickerBottomToolBar) {
        delegate?.preview(selectedItems: photoScrollPicker.selectedItems,
                          useOriginal: bottomToolBar.isOriginal())
    }

    func bottomToolBarDidClickSendButton(_ bottomToolBar: PhotoPickerBottomToolBar) {
        delegate?.pickedImages(images: photoScrollPicker.selectedItems,
                               useOriginal: bottomToolBar.isOriginal())
        self.clear()
    }
}

extension PhotoPickView: PhotoPickerTipsViewDelegate {
    func photoPickerTipsViewSettingButtonClick(_ tipsView: PhotoPickerTipsView) {
        delegate?.goSetting()
    }
}

extension PhotoPickView: PhotoScrollPickerDelegate {
    func itemSelected(asset: PHAsset) {}

    func itemDeSelected(itemIdentifier: String) {}

    func selectReachMax(type: PhotoPickerSelectDisableType) {
        guard let window = self.window else { return }
        let title: String
        switch type {
        case .cannotMix:
            let tip = reachMaxCountTipBlock?(.cannotMix)
            title = tip ?? BundleI18n.LarkAssetsBrowser.Lark_Legacy_SelectPhotosOrVideosError
        case .maxImageCount(let count):
            let tip = reachMaxCountTipBlock?(.maxImageCount(count))
            title = tip ?? String(format: BundleI18n.LarkAssetsBrowser.Lark_Legacy_MaxImageLimitReachedMessage, count)
        case .maxVideoCount(let count):
            let tip = reachMaxCountTipBlock?(.maxVideoCount(count))
            title = tip ?? String(format: BundleI18n.LarkAssetsBrowser.Lark_Legacy_MaxVideoLimitReachedMessage, count)
        case .maxAssetsCount(let count):
            let tip = reachMaxCountTipBlock?(.maxAssetsCount(count))
            title = tip ?? BundleI18n.LarkAssetsBrowser.Lark_Legacy_Max9Items(count)
        }
        UDToast.showTips(with: title, on: window)
    }

    func preview(asset: PHAsset, selectedImages: [PHAsset]) {
        delegate?.preview(asset: asset, selectedImages: selectedImages, useOriginal: bottomToolBar.isOriginal())
    }

    func selectedItemsChanged(imageItems: [PHAsset]) {
        bottomToolBar.set(selectCount: imageItems.count)
        delegate?.pickedImagesChange(images: imageItems, useOriginal: bottomToolBar.isOriginal())
    }

    func selectedOrPreviewItemInCloud() {
        PhotoIniCloudStatusBarNotification
            .shared
            .showNotification(content: BundleI18n.LarkAssetsBrowser.Lark_Legacy_AlertPhotoincloud,
                              reNew: true)
    }

    func setOriginalButton(_ isEnable: Bool) {
        bottomToolBar.set(isOriginEnable: isEnable)
    }

    public func set(isOrigin: Bool) {
        bottomToolBar.set(isOrigin: isOrigin)
    }

    func photoScrollPickerReload(with assetResult: PHFetchResult<PHAsset>) {
        delegate?.photoPickerReload(with: assetResult)
    }
}
