//
//  PhotoScrollPicker.swift
//  LarkUIKit
//
//  Created by zc09v on 2017/6/8.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import Photos
import SnapKit
import RxCocoa
import LarkUIKit
import LarkExtensions
import LarkFoundation
import LarkSensitivityControl
import LKCommonsLogging
import AppReciableSDK
import ByteWebImage
import UniverseDesignToast
import UniverseDesignColor

final class PhotoScrollPicker: UIView {
    fileprivate var fetchResult: PHFetchResult<PHAsset> = PHFetchResult<PHAsset>() {
        didSet {
            fillAssets()
        }
    }

    /// 标识位，多次 fetch 时，只保留最新一次的结果
    private var lastFetchTime: TimeInterval = 0

    private var hud: UDToast?
    private lazy var iCloudImageDownloader = ICloudImageDownloader()
    static let logger = Logger.log(
        PhotoScrollPicker.self,
        category: "LarkAssetBrowser.ImagePicker.PhotoScrollPicker")
    private var disposedKey: DisposedKey?
    private(set) var showCount = 0
    fileprivate var hasPermission: Bool = false
    fileprivate var fetchLimit: Int = 50
    fileprivate var showed: Bool = false
    private let imageCache: ImageCache
    fileprivate let editImage: (String) -> UIImage?
    fileprivate let editVideo: (String) -> URL?

    /// 选择视频时，是否支持点击"原图"按钮
    private let originVideo: Bool

    var assetType: PhotoPickerAssetType
    var cellSupportPanGesture = true
    var supportPreviewImage = true
    var selectedItems: [PHAsset] = [] {
        didSet {
            selectedItemsDidChange?(selectedItems)
        }
    }

    var fromMoment: Bool = false

    var selectedItemsDidChange: (([PHAsset]) -> Void)?
    weak var delegate: PhotoScrollPickerDelegate?

    fileprivate lazy var layout: PhotoScrollPickerCollectionLayout = {
        let layout = PhotoScrollPickerCollectionLayout(itemCount: showCount)
        layout.scrollDirection = .horizontal
        return layout
    }()

    fileprivate lazy var imageCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.ud.N50
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        let cellIndentifier = String(describing: PhotoScrollPickerCell.self)
        collectionView.register(PhotoScrollPickerCell.self, forCellWithReuseIdentifier: cellIndentifier)
        return collectionView
    }()

    fileprivate lazy var noPhotoTipView: NoPhotoTipView = {
        let noPhotoTipView = NoPhotoTipView()
        noPhotoTipView.alpha = 0
        return noPhotoTipView
    }()

    let photoLibrary = PHPhotoLibrary.shared()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        photoLibrary.unregisterChangeObserver(self)
    }

    override var bounds: CGRect {
        didSet {
            if self.bounds != oldValue {
                clearSizeCache()
                reloadCollection()
            }
        }
    }

    init(assetType: PhotoPickerAssetType,
         originVideo: Bool,
         imageCache: ImageCache,
         editImage: @escaping (String) -> UIImage?,
         editVideo: @escaping (String) -> URL?) {
        self.assetType = assetType
        self.originVideo = originVideo
        self.imageCache = imageCache
        self.editImage = editImage
        self.editVideo = editVideo
        super.init(frame: .zero)
        setupSubviews()
        backgroundColor = UIColor.ud.N50
    }

    private func setupSubviews() {
        self.addSubview(self.imageCollectionView)
        self.addSubview(self.noPhotoTipView)
        self.imageCollectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.noPhotoTipView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func show(with completion: @escaping (PHAuthorizationStatus) -> Void) {
        guard !showed else {
            return
        }
        showed = true
        try? Utils.checkPhotoReadWritePermission(token: AssetBrowserToken.checkPhotoReadWritePermission.token) { (granted) in
            self.hasPermission = granted
            if self.hasPermission {
                self.reloadAssets()
                self.disposedKey = AssetsPickerTracker.start(fromMoent: self.fromMoment, from: .keyboard)
            } else {
                let permissionView = PermissionView()
                self.addSubview(permissionView)
                permissionView.snp.makeConstraints({ (make) in
                    make.edges.equalToSuperview()
                })
            }
            let status: PHAuthorizationStatus
            if #available(iOS 14, *) {
                status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            } else {
                status = PHPhotoLibrary.authorizationStatus()
            }
            completion(status)
        }
    }

    func reloadAssets() {
        let fetchTime = Date().timeIntervalSince1970
        self.lastFetchTime = fetchTime
        DispatchQueue.global().async {
                    let options = PHFetchOptions()
            options.predicate = self.predicate()
            let collect = try? AlbumEntry.fetchAssetCollections(
                forToken: AssetBrowserToken.fetchAssetCollections.token,
                withType: .smartAlbum,
                subtype: .smartAlbumUserLibrary,
                options: nil
            ).firstObject

            let fetchResult = collect.flatMap { PHAsset.fetchAssets(in: $0, options: options) } ?? PHFetchResult<PHAsset>()
            DispatchQueue.main.async {
                self.photoLibrary.register(self)
                guard fetchTime >= self.lastFetchTime else { return }
                self.fetchResult = fetchResult
                // 使用正确的 showCount 更新，imageSizeCache 长度。在 这个界面第一次进行权限获取时会取得一个 showCount == 0的值，导致后续取值时 下标越界。
                self.layout.imageSizeCache = [CGSize](repeating: .zero, count: self.showCount)
                let number = self.showCount
                if number == 0 {
                    self.noPhotoTipView.alpha = 1
                    if collect == nil {
                        self.noPhotoTipView.label.text = BundleI18n.LarkAssetsBrowser.Lark_Chat_GetPhotoFailed
                    }
                }
                self.delegate?.photoScrollPickerReload(with: self.fetchResult)
                self.reloadCollection()
            }
        }
    }

    private func fillAssets() {
        // 用num不用count，因为count会有swiftlint问题
        let num = min(fetchLimit, fetchResult.count)
        if num > 0 {
            self.showCount = num
        }
    }

    private func predicate() -> NSPredicate {
        let maker: (PHAssetMediaType) -> NSPredicate = {
            NSPredicate(format: "mediaType == %d", $0.rawValue)
        }
        switch assetType {
        case .imageOnly:
            return maker(.image)
        case .videoOnly:
            return maker(.video)
        case .imageOrVideo, .imageAndVideo, .imageAndVideoWithTotalCount:
            return NSCompoundPredicate(orPredicateWithSubpredicates: [maker(.image), maker(.video)])
        }
    }

    func updateSelectedItemsStatus() {
        guard hasPermission else {
            return
        }
        updateVisibleCellSelectStatus()
        updateVisibleCellMaskView()
        customOriginalButtonEnable()
    }

    private func updateVisibleCellSelectStatus() {
        for index in imageCollectionView.indexPathsForVisibleItems {
            if let visibleAsset = assetAtRow(index.row),
                let collectionCell = imageCollectionView.cellForItem(at: index) as? PhotoScrollPickerCell {
                collectionCell.selectIndex = selectedItems.firstIndex(of: visibleAsset)
            }
        }
    }

    func reloadCollection() {
        imageCollectionView.reloadData()
    }

    func clearSelectItems() {
        guard hasPermission else {
            return
        }

        selectedItems = []

        for cell in imageCollectionView.visibleCells.compactMap({ $0 as? PhotoScrollPickerCell }) {
            cell.selectIndex = nil
            cell.setMaskView(isHidden: true)
        }
    }

    func clearSizeCache() {
        layout.imageSizeCache = layout.imageSizeCache.map { (_) in .zero }
    }

    private func shouldHiddenCellMaskView(_ isVideo: Bool, asset: PHAsset?) -> Bool {
        let selectedImages = selectedItems.filter { $0.mediaType == .image }
        let selectedVideos = selectedItems.filter { $0.mediaType == .video }

        let isImageReachMax = (selectedImages.count == assetType.maxImageCount)
        let isVideoReachMax = (selectedVideos.count == assetType.maxVideoCount)

        var isSameType = true
        if let firstAsset = selectedItems.first, firstAsset.mediaType != asset?.mediaType {
            isSameType = false
        }

        switch assetType {
        case .imageOnly:
            return !isImageReachMax && isSameType
        case .videoOnly:
            return !isVideoReachMax && isSameType
        case .imageOrVideo:
            return !isImageReachMax && !isVideoReachMax && isSameType
        case .imageAndVideo:
            if isVideo, isVideoReachMax {
                return false
            } else if !isVideo, isImageReachMax {
                return false
            } else {
                return true
            }
        case .imageAndVideoWithTotalCount(totalCount: let totalCount):
            return !(selectedItems.count == totalCount)
        }
    }

    func updateVisibleCellMaskView() {
        for cell in imageCollectionView.visibleCells
            .compactMap({ $0 as? PhotoScrollPickerCell })
            .filter({ $0.selectIndex == nil }) {
            cell.setMaskView(isHidden: shouldHiddenCellMaskView(cell.isVideo, asset: cell.currentAsset))
        }
    }

    func customOriginalButtonEnable() {
        let enable: Bool
        switch assetType {
        case .videoOnly:
            enable = self.originVideo
        case .imageOnly:
            enable = true
        case .imageAndVideo, .imageAndVideoWithTotalCount:
            // 可以混合选择图片和视频，And：分别有数量限制，Total：一共有数量限制
            enable = true
        case .imageOrVideo:
            // 只能选择图片或者视频，不能同时选择两种资源，两种资源分别有数量限制
            if let first = selectedItems.first, first.mediaType == .video, !self.originVideo {
                delegate?.set(isOrigin: false)
                enable = false
            } else {
                enable = true
            }
        }
        delegate?.setOriginalButton(enable)
    }

    private func assetAtRow(_ row: Int) -> PHAsset? {
        guard row >= 0, row < fetchResult.count else { return nil }
        return fetchResult.object(at: fetchResult.count - 1 - row)
    }

    private func canSelectedAsset(_ asset: PHAsset) -> Bool {
        var selectedAssets = self.selectedItems
        selectedAssets.lf_appendIfNotContains(asset)
        let selectedImages = selectedAssets.filter { $0.mediaType == .image }
        let selectedVideos = selectedAssets.filter { $0.mediaType == .video }

        switch assetType {
        /// 只能选择图片
        case .imageOnly(let maxCount):
            if selectedImages.count > assetType.maxImageCount {
                delegate?.selectReachMax(type: .maxImageCount(assetType.maxImageCount))
                return false
            } else if !selectedVideos.isEmpty {
                delegate?.selectReachMax(type: .cannotMix)
                return false
            } else {
                return true
            }
        /// 只能选择视频
        case .videoOnly(let maxCount):
            if selectedVideos.count > assetType.maxVideoCount {
                delegate?.selectReachMax(type: .maxVideoCount(assetType.maxVideoCount))
                return false
            } else if !selectedImages.isEmpty {
                delegate?.selectReachMax(type: .cannotMix)
                return false
            } else {
                return true
            }
        /// 只能选择图片或者视频
        case .imageOrVideo(let imageMaxCount, let videoMaxCount):
            if !selectedImages.isEmpty && !selectedVideos.isEmpty {
                delegate?.selectReachMax(type: .cannotMix)
                return false
            } else if let firstAsset = selectedItems.first, firstAsset.mediaType != asset.mediaType {
                delegate?.selectReachMax(type: .cannotMix)
                return false
            } else if selectedImages.count > imageMaxCount {
                delegate?.selectReachMax(type: .maxImageCount(assetType.maxImageCount))
                return false
            } else if selectedVideos.count > videoMaxCount {
                delegate?.selectReachMax(type: .maxVideoCount(assetType.maxVideoCount))
                return false
            } else {
                return true
            }
        /// 可以选择图片加视频，分别都有数量限制
        case .imageAndVideo(let imageMaxCount, let videoMaxCount):
            if selectedImages.count > imageMaxCount {
                delegate?.selectReachMax(type: .maxImageCount(imageMaxCount))
                return false
            } else if selectedVideos.count > videoMaxCount {
                delegate?.selectReachMax(type: .maxImageCount(videoMaxCount))
                return false
            } else {
                return true
            }
        /// 可以选择图片加视频，有总数限制
        case .imageAndVideoWithTotalCount(let totalCount):
            if selectedAssets.count > totalCount {
                delegate?.selectReachMax(type: .maxAssetsCount(totalCount))
                return false
            } else {
                return true
            }
        }
    }

    private func onSelect(_ cell: PhotoScrollPickerCell, asset: PHAsset) {
        guard canSelectedAsset(asset) else {
            cell.selectIndex = nil
            return
        }
        imageCache.addAsset(asset: asset, image: cell.imageView.image)
        selectedItems.append(asset)
        // 获取cell的index
        cell.selectIndex = selectedItems.lastIndex(of: asset)
        updateVisibleCellMaskView()
        customOriginalButtonEnable()
        delegate?.itemSelected(asset: asset)
        delegate?.selectedItemsChanged(imageItems: selectedItems)
    }

    private func onDeselect(_ cell: PhotoScrollPickerCell, asset: PHAsset) {
        cell.selectIndex = nil
        imageCache.removeAsset(asset)
        selectedItems = selectedItems.filter({ (item) -> Bool in
            return item != asset
        })
        self.updateVisibleCellMaskView()
        self.reloadDisplayCellsForNumber()
        customOriginalButtonEnable()
        self.delegate?.itemDeSelected(itemIdentifier: asset.localIdentifier)
        self.delegate?.selectedItemsChanged(imageItems: selectedItems)
    }

    /**
     由于取消的时候需要修改之前的数字
     比如 3 4 5 6 -> 取消3的话 其他的需要修改为 3 4 5
     */
    private func reloadDisplayCellsForNumber() {
        for cell in imageCollectionView.visibleCells {
            let pickerCell = cell as? PhotoScrollPickerCell
            // 找出当前界面被选中的cell 然后更显cell上显示的数字
            if pickerCell?.selectIndex != nil, let visibleCell = pickerCell, let asset = visibleCell.currentAsset {
                visibleCell.selectIndex = selectedItems.firstIndex(of: asset)
            }

        }
    }
}

extension PhotoScrollPicker: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // UICollectionView与UITableview机制不太一样，cell消失后，再出现，cellForItemAt不一定会调用
        if let asset = assetAtRow(indexPath.row), let collectionCell = cell as? PhotoScrollPickerCell {
            // 主要处理首屏的时候需要设置最右边cell的checkBox的位置
            // 和复用cell后位置需要重新调整
            let cellFrameInPicker = collectionView.convert(collectionCell.frame, to: self)
            // 通过cell的maxX是否大于顶层容器的宽度判断是否是最右边的cell
            if cellFrameInPicker.maxX >= self.frame.width {
                collectionCell.moveCheckBoxFrame(picker: self)
            } else {
                collectionCell.resetCheckBoxFrame()
            }
            if selectedItems.contains(asset) {
                collectionCell.selectIndex = selectedItems.firstIndex(of: asset)
                collectionCell.setMaskView(isHidden: true)
            } else {
                collectionCell.selectIndex = nil
                collectionCell.setMaskView(isHidden: self.shouldHiddenCellMaskView(collectionCell.isVideo, asset: asset))
            }

            if collectionView.isDragging {
                collectionCell.panGesture.isEnabled = false
            } else {
                collectionCell.panGesture.isEnabled = true
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIndentifier = String(describing: PhotoScrollPickerCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIndentifier, for: indexPath)
        let row = indexPath.row

        if let asset = assetAtRow(indexPath.row), let collectionCell = cell as? PhotoScrollPickerCell {
            collectionCell.imageIndentify = asset.localIdentifier
            collectionCell.imageTag = LkNavigationController.CancelPopGestureTag
            collectionCell.delegate = self
            collectionCell.currentAsset = asset
            collectionCell.cellSupportPanGesture = cellSupportPanGesture
            if let editImage = editImage(asset.localIdentifier) {
                collectionCell.updateImage(indentifier: asset.localIdentifier, request: .image(editImage))
            } else if let editVideo = editVideo(asset.localIdentifier) {
                let targetSize = CGSize(width: layout.imageSizeCache[row].width, height: layout.imageSizeCache[row].height) * UIScreen.main.scale
                let avasset = AVURLAsset(url: editVideo)
                let generator: AVAssetImageGenerator = AVAssetImageGenerator(asset: avasset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = targetSize
                if let cgimage = try? generator.copyCGImage(at: CMTimeMake(value: 0, timescale: 10), actualTime: nil) {
                    collectionCell.updateImage(indentifier: asset.localIdentifier, request: .image(UIImage(cgImage: cgimage)))
                }
            } else {
                let targetSize = CGSize(width: layout.imageSizeCache[row].width, height: layout.imageSizeCache[row].height) * UIScreen.main.scale
                let requestOptions = PHImageRequestOptions()
                requestOptions.version = .current
                requestOptions.deliveryMode = .opportunistic
                requestOptions.resizeMode = .fast
                requestOptions.isNetworkAccessAllowed = true
                _ = try? AlbumEntry.requestImage(forToken: AssetBrowserToken.requestImage.token,
                                                 manager: PHCachingImageManager.default(),
                                                 forAsset: asset,
                                                 targetSize: targetSize,
                                                 contentMode: .aspectFill,
                                                 options: requestOptions) { image, info in
                        guard let image = image, asset.localIdentifier == (collectionCell.imageIndentify ?? "") else { return }
                        let isInCloudy = info?[PHImageResultIsInCloudKey] as? Bool ?? false
                        collectionCell.updateImage(indentifier: asset.localIdentifier, request: isInCloudy ? .iniCloud(image) : .image(image))
                    }
            }
            collectionCell.setVideoTag(isVideo: asset.mediaType == .video, time: asset.duration)
        }
        if let key = self.disposedKey {
            AssetsPickerTracker.end(key: key)
            self.disposedKey = nil
        }
        DispatchQueue.main.async {
            if indexPath.row == collectionView.numberOfItems(inSection: indexPath.section) - 1 {
                self.loadMoreData()
            }
        }

        return cell
    }

    private func loadMoreData() {
        let newShowCount = min(showCount + fetchLimit, fetchResult.count)
        if newShowCount != showCount {
            showCount = newShowCount
            if newShowCount > layout.imageSizeCache.count {
                layout.imageSizeCache.append(contentsOf: (0..<showCount - layout.imageSizeCache.count).map { _ in CGSize.zero })
            }
            self.imageCollectionView.reloadData()
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return showCount
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
        ) -> CGSize {
        let row = indexPath.row

        guard let asset = assetAtRow(indexPath.row) else { return .zero }
        if editImage(asset.localIdentifier) != nil {
            layout.imageSizeCache[row] = .zero
        }
        if layout.imageSizeCache[row] != .zero {
            return layout.imageSizeCache[row]
        } else {
            let width: CGFloat
            let height: CGFloat
            if let editImage = editImage(asset.localIdentifier) {
                width = editImage.size.width
                height = editImage.size.height
            } else {
                width = CGFloat(asset.pixelWidth) / UIScreen.main.scale
                height = CGFloat(asset.pixelHeight) / UIScreen.main.scale
            }

            if width == 0 || height == 0 {
                // NOTE: 取不到图片大小 设置为一个正方形占位
                let size = CGSize(width: self.frame.height, height: self.frame.height)
                layout.imageSizeCache[row] = size
                return size
            }

            let ratio = self.frame.height / height
            var realWidth = width * ratio
            if realWidth < 80 {
                realWidth = 80
            } else if realWidth > 400 {
                realWidth = 400
            }

            if self.frame.height <= 0 {
                return CGSize(width: realWidth, height: 1)
            } else {
                let size = CGSize(width: realWidth, height: self.frame.height)
                layout.imageSizeCache[row] = size
                return size
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoScrollPickerCell {
            guard let asset = assetAtRow(indexPath.row) else { return }
            guard !cell.iniCloud else {
                self.delegate?.selectedOrPreviewItemInCloud()
                return
            }

            guard !supportPreviewImage else {
                self.delegate?.preview(
                    asset: asset,
                    selectedImages: selectedItems
                )
                return
            }

            if selectedItems.contains(asset) {
                onDeselect(cell, asset: asset)
            } else {
                onSelect(cell, asset: asset)
            }
        }
    }
}

extension PhotoScrollPicker: PhotoScrollPickerCellDelegate {
    func cellSelected(selected: Bool, cell: PhotoScrollPickerCell) {
        if let indexPath = self.imageCollectionView.indexPath(for: cell), let asset = assetAtRow(indexPath.row) {
            if selected {
                if asset.isInICloud {
                    let requestID = iCloudImageDownloader.downloadAsset(with: asset, progressBlock: nil) { [weak self] result in
                        switch result {
                        case .success(let data):
                            DispatchQueue.main.async {
                                self?.removeSyncLoadingHud()
                                if let image = data as? UIImage {
                                    cell.imageView.image = image
                                }
                                self?.onSelect(cell, asset: asset)
                                PhotoScrollPicker.logger.info("Download asset from iCloud success!")
                            }
                        case .failure(let error):
                            /// Avoid repainting collectionView too often after download failure
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                guard let self = self else { return }
                                self.removeSyncLoadingHud()
                                self.onDeselect(cell, asset: asset)
                                ICloudImageDownloader.toastError(error, on: self.toastView)
                                PhotoScrollPicker.logger.error("Download asset from iCloud failed: \(error)")
                            }
                        }
                    }
                    self.hud = ICloudImageDownloader.showSyncLoadingToast(on: self.toastView, cancelCallback: { [weak self] in
                        self?.onDeselect(cell, asset: asset)
                        if let requestID = requestID {
                            self?.iCloudImageDownloader.cancel(requestID: requestID)
                        }
                    })
                } else {
                    onSelect(cell, asset: asset)
                }
            } else {
                onDeselect(cell, asset: asset)
            }
        }
    }

    func releaseCellOutside(cell: PhotoScrollPickerCell) {
        if let index = self.imageCollectionView.indexPath(for: cell), let asset = assetAtRow(index.row) {
            guard !cell.iniCloud else {
                self.delegate?.selectedOrPreviewItemInCloud()
                return
            }

            self.delegate?.itemSelectedByPanGesture(asset: asset)
        }
    }

    func cellIsDragging(cell: PhotoScrollPickerCell) {
        imageCollectionView.clipsToBounds = false
    }

    func cellIsStopDragging(cell: PhotoScrollPickerCell) {
        imageCollectionView.clipsToBounds = true
    }
}

extension PhotoScrollPicker: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        for cell in imageCollectionView.visibleCells {
            if let photoScrollPickerCell = cell as? PhotoScrollPickerCell {
                photoScrollPickerCell.panGesture.isEnabled = false
            }
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        for cell in imageCollectionView.visibleCells {
            if let photoScrollPickerCell = cell as? PhotoScrollPickerCell {
                photoScrollPickerCell.panGesture.isEnabled = true
            }
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        for cell in imageCollectionView.visibleCells {
            if let photoScrollPickerCell = cell as? PhotoScrollPickerCell {
                photoScrollPickerCell.panGesture.isEnabled = true
            }
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // visibleCells.last可能取的不是屏幕最右边的cell, 因此这里对visibleCells根据frame进行一个排序后再取last
        guard let lastVisibleCell = imageCollectionView.visibleCells.sorted { (left, right) -> Bool in
                guard let leftPath = imageCollectionView.indexPath(for: left),
                      let rightPath = imageCollectionView.indexPath(for: right) else {
                    return false
                }
                return leftPath.row < rightPath.row
            }.last else {
            return
        }
        guard let lastCell = lastVisibleCell as? PhotoScrollPickerCell else {
            return
        }
        // 跟随滑动动态设置cell的checkbox位置
        lastCell.moveCheckBoxFrame(picker: self)
    }
}

extension PhotoScrollPicker: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            if let changes = changeInstance.changeDetails(for: self.fetchResult) {

                let removedIds = changes.removedObjects.map { $0.localIdentifier }
                let fileteredItems = self.selectedItems.filter { !removedIds.contains($0.localIdentifier) }
                let selectedItemsHasChange = (fileteredItems != self.selectedItems)
                self.selectedItems = fileteredItems

                self.fetchResult = changes.fetchResultAfterChanges

                let number = self.showCount
                if number > 0 {
                    self.noPhotoTipView.alpha = 0
                } else {
                    self.noPhotoTipView.alpha = 1
                }
                self.layout.imageSizeCache = [CGSize](repeating: .zero, count: self.showCount)
                self.delegate?.photoScrollPickerReload(with: self.fetchResult)
                self.reloadCollection()
                if selectedItemsHasChange {
                    self.delegate?.selectedItemsChanged(imageItems: self.selectedItems)
                }
            }
        }
    }
}

// MARK: iCloud download toast
extension PhotoScrollPicker {
    private var toastView: UIView {
        self.window ?? self
    }
    private func removeSyncLoadingHud() {
        self.hud?.remove()
        self.hud = nil
    }
}

private final class PermissionView: UIView {
    let label: UILabel
    let button: UIButton
    override init(frame: CGRect) {
        label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 3
        label.textColor = UIColor.ud.N500

        button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.N50
        button.addTarget(self, action: #selector(gotoSettings), for: .touchUpInside)
        self.addSubview(label)
        self.addSubview(button)

        if Utils.hasTriggeredIOS17PhotoPermissionBug(), !PhotoAuthorityFixer.isIOS17PermissionBugFixed {
            label.numberOfLines = 0
            label.text = BundleI18n.LarkAssetsBrowser.Lark_IM_CantEditPhotoAccessDownloadAgain_iOS_Text()
            button.setTitle(BundleI18n.LarkAssetsBrowser.Lark_IM_CantEditPhotoAccessDownloadAgain_GoToSettings_iOS_Button, for: .normal)
        } else {
            label.text = BundleI18n.LarkAssetsBrowser.Lark_Legacy_PhotoLibraryForbbiden()
            button.setTitle(BundleI18n.LarkAssetsBrowser.Lark_IM_NoAlbumAccessEnableInSettings_Button, for: .normal)
        }

        label.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().inset(8)
            make.top.equalTo(86)
        }

        button.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(label.snp.bottom).offset(15)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func gotoSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings)
        }
    }
}

private final class NoPhotoTipView: UIView {
    let label: UILabel
    override init(frame: CGRect) {
        label = UILabel()
        label.text = BundleI18n.LarkAssetsBrowser.Lark_Legacy_NoPhoto
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N500
        label.textAlignment = .center
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.N50
        self.addSubview(label)

        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().offset(10)
            make.right.greaterThanOrEqualToSuperview().offset(-10)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
