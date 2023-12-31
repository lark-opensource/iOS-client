//
//  AssetGridSingleSelectViewController.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/9/11.
//

import Foundation
import UIKit
import SnapKit
import Photos
import LarkUIKit
import AppReciableSDK
import UniverseDesignToast
import LKCommonsLogging
import LKCommonsTracker

private let kCollectionViewHeaderIdentifier = "kCollectionViewHeaderIdentifier"

class AssetGridBaseViewController: AssetPickerSubViewController,
                                   UICollectionViewDataSource,
                                   UICollectionViewDelegateFlowLayout,
                                   PHPhotoLibraryChangeObserver,
                                   UIViewControllerTransitioningDelegate,
                                   PhotoPickerTipsViewDelegate {
    
    fileprivate static let logger = Logger.log(AssetGridBaseViewController.self, category: "AssetGridVC")
    
    private let itemSpacing: CGFloat = 1
    private let numberOfItemPerRow: Int = 4
    private var isFirstLayoutSubviews = true
    var disposedKey: DisposedKey?
    var fromMoment: Bool = false
    
    // MARK: - UI Elements
    
    private let albumTitleView = AlbumTitleView()
    
    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = itemSpacing
        layout.minimumInteritemSpacing = itemSpacing
        layout.sectionHeadersPinToVisibleBounds = true
        return layout
    }()
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.register(SelectMoreCell.self, forCellWithReuseIdentifier: SelectMoreCell.identifier)
        collectionView.register(AssetGridCell.self, forCellWithReuseIdentifier: String(describing: AssetGridCell.self))
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kCollectionViewHeaderIdentifier)
        return collectionView
    }()
    
    // save album list vc for next use
    private var albumListViewController: AlbumListViewController?

    // MARK: - Data Source
    
    // Record current displayed album
    var currentAlbum: Album = Album.empty
    // Provide album data
    private let albumDataCenter: AlbumListDataCenter
    // Observe photo libray changes
    private let photoLibrary = PHPhotoLibrary.shared()
    // Request image thumbnails, used by subclass
    let imageManager = PHCachingImageManager.default()

    init(dataCenter: AlbumListDataCenter) {
        self.albumDataCenter = dataCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody

        // navigation bar right button
        let cancelItem = LKBarButtonItem(image: nil, title: BundleI18n.LarkAssetsBrowser.Lark_Legacy_Cancel)
        cancelItem.button.addTarget(self, action: #selector(cancelItemDidTap), for: .touchUpInside)
        cancelItem.setBtnColor(color: UIColor.ud.textTitle)
        navigationItem.leftBarButtonItem = cancelItem
        
        // navigation bar center view
        albumTitleView.setTitle(currentAlbum.localizedTitle)
        albumTitleView.setTitleColor(UIColor.ud.textTitle)
        albumTitleView.addTarget(self, action: #selector(titleButtonDidClick), for: .touchUpInside)
        navigationItem.titleView = albumTitleView

        // main content view
        collectionView.delegate = self
        collectionView.dataSource = self
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        // register photo library observer
        photoLibrary.register(self)
    }

    deinit {
        // remove photo library observer
        photoLibrary.unregisterChangeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let disposeKey = AssetsPickerTracker.start(fromMoent: fromMoment, from: .gallery)
    }

    override func viewDidLayoutSubviews() {
        if isFirstLayoutSubviews {
            isFirstLayoutSubviews = false
            // update item size
            updateItemSize(containerSize: view.bounds.size)
            // reload photos from album
            DispatchQueue.global().async {
                let defaultAlbum = self.albumDataCenter.defaultAlbum
                DispatchQueue.main.async {
                    self.reloadWithAlbum(defaultAlbum ?? .empty, resetContentOffset: true)
                    self.albumTitleView.isHidden = defaultAlbum == nil
                }
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateItemSize(containerSize: size)
        collectionView.reloadData()
    }

    /// AlbumListVC 选中不同 album 以后，更新 UI
    private func reloadWithAlbum(_ album: Album, resetContentOffset: Bool = true) {
        guard currentAlbum != album else { return }
        currentAlbum = album
        albumTitleView.setTitle(album.localizedTitle)
        collectionView.reloadData()
        if resetContentOffset {
            self.collectionView.alpha = 0
            collectionView.performBatchUpdates(nil) { _ in
                self.collectionView.scrollToBottom()
                self.collectionView.alpha = 1
            }
        }
    }

    @objc
    private func titleButtonDidClick() {
        // save album list view controller for next time use.
        if let albumListVC = albumListViewController {
            present(albumListVC, animated: true, completion: nil)
        } else {
            UDToast.showDefaultLoading(on: view)
            DispatchQueue.global().async {
                let allAlbums = self.albumDataCenter.allAlbums
                DispatchQueue.main.async {
                    UDToast.removeToast(on: self.view)
                    let albumListVC = AlbumListViewController(albums: allAlbums,
                                                              defaultSelectAlbum: self.currentAlbum)
                    self.albumListViewController = albumListVC
                    albumListVC.didSelectAlbum = { [weak self] (album) in
                        self?.reloadWithAlbum(album, resetContentOffset: true)
                        albumListVC.dismiss(animated: true, completion: nil)
                    }
                    albumListVC.transitioningDelegate = self
                    albumListVC.modalPresentationStyle = .overCurrentContext
                    self.present(albumListVC, animated: true, completion: nil)
                }
            }
        }
    }

    func calculateItemSize(containerSize: CGSize) -> CGSize {
        let itemsPerRow = numberOfItemPerRow
        let itemWidth = (containerSize.width - CGFloat(itemsPerRow - 1) * itemSpacing) / CGFloat(itemsPerRow)
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    private func updateItemSize(containerSize: CGSize) {
        layout.itemSize = calculateItemSize(containerSize: containerSize)
        layout.prepare()
        layout.invalidateLayout()
    }
    
    // MARK: - CollectionView DataSourve & Delegate
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentAlbum.assetsCount + (PhotoPickView.preventStyle == .limited ? 1 : 0)
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        assertionFailure("应该由子类实现")
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        assertionFailure("应该由子类实现")
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 && PhotoPickView.preventStyle.showTips() {
            return CGSize(width: self.view.bounds.width, height: 44)
        }
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let reuseView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kCollectionViewHeaderIdentifier, for: indexPath)
        if PhotoPickView.preventStyle.showTips() && indexPath.section == 0 && kind == UICollectionView.elementKindSectionHeader {
            let tipsView = PhotoPickerTipsView()
            tipsView.delegate = self
            tipsView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 44)
            reuseView.addSubview(tipsView)
            return reuseView
        }
        return reuseView
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let presented = presented as? AlbumListViewController {
            return AlbumListPresentTransition(transitionView: presented.tableViewWrapper)
        }
        return nil
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let dismissed = dismissed as? AlbumListViewController {
            return AlbumListDismissTransition(transitionView: dismissed.tableViewWrapper)
        }
        return nil
    }
    
    // MARK: - PHPhotoLibraryChangeObserver
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if let details = changeInstance.changeDetails(for: currentAlbum.fetchResult) {
            let newFetchResult = details.fetchResultAfterChanges
            DispatchQueue.main.async { [self] in
                let newAlbum = Album(collection: currentAlbum.collection,
                                     fetchResult: newFetchResult,
                                     isReversed: currentAlbum.isReversed)
                selectedAssets.forEach {
                    if !newFetchResult.contains($0) {
                        deselectAsset($0)
                    }
                }
                reloadWithAlbum(newAlbum, resetContentOffset: false)
            }
        }
    }
    
    // MARK: - PhotoPickerTipsViewDelegate

    func photoPickerTipsViewSettingButtonClick(_ tipsView: PhotoPickerTipsView) {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

fileprivate extension UICollectionView {
    
    private var logger: Log {
        AssetGridBaseViewController.logger
    }

    private var lastIndexPath: IndexPath? {
        let lastSection = numberOfSections - 1
        guard lastSection >= 0 else {
            logger.error("calculate lastIndexPath failed, lastSection \(lastSection)")
            return nil
        }
        let lastItem = numberOfItems(inSection: lastSection) - 1
        guard lastItem >= 0 else {
            logger.error("calculate lastIndexPath failed, lastItem \(lastItem)")
            return nil
        }
        logger.info("calculate lastIndexPath succeed, lastItem \(lastItem), lastSection \(lastSection)")
        return IndexPath(item: lastItem, section: lastSection)
    }

    /// 通过设定 indexPath 将 collectionView 滚动到最后
    func scrollToBottom(animated: Bool = false) {
        logger.info("ready scroll to bottom.")
        guard let lastIndexPath = lastIndexPath else {
            self.scrollToBottomBackup(animated: animated)
            return
        }
        logger.info("trying scroll to bottom by indexPath: \(lastIndexPath)")
        scrollToItem(at: lastIndexPath, at: .bottom, animated: animated)
        // 兜底策略：当滚动不成功时，使用 contentOffset 再次尝试滚动到底部
        DispatchQueue.main.async {
            if self.contentOffset.y <= 0, self.contentSize.height > self.bounds.height {
                self.logger.error("scroll to bottom with indexPath failed, contentOffsetY: \(self.contentOffset.y)")
                self.scrollToBottomBackup(animated: animated)
            } else {
                self.logger.info("scroll to bottom with indexPath succeed, contentOffsetY: \(self.contentOffset.y)")
            }
        }
    }
    
    /// 通过设定 contentOffset 将 collectionView 滚动到最后
    /// - Parameters:
    ///   - maxRetryTimes: 剩余重试次数，当 scrollToBottom 失败时，一段时间后再次尝试
    private func scrollToBottomBackup(animated: Bool = false, maxRetryTimes: Int = 1) {
        guard maxRetryTimes >= 0 else { return }
        self.setNeedsLayout()
        self.layoutIfNeeded()
        let bottomOffset = CGPoint(x: 0, y: self.contentSize.height - self.bounds.height + self.contentInset.bottom)
        let adjustedContentInset = self.adjustedContentInset
        let bottomContentOffset = CGPoint(x: 0, y: max(bottomOffset.y, CGFloat(-adjustedContentInset.top)))
        logger.info("trying scroll to bottom by content offset: \(bottomContentOffset), remaining retry times: \(maxRetryTimes)")
        self.setContentOffset(bottomContentOffset, animated: false)
        // 双重兜底策略：一段时间后再次检查 offset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if self.contentOffset.y <= 0, self.contentSize.height > self.bounds.height {
                self.logger.error("scroll to bottom with content offset failed, contentOffsetY: \(self.contentOffset.y)")
                self.scrollToBottomBackup(animated: false, maxRetryTimes: maxRetryTimes - 1)
            } else {
                self.logger.error("scroll to bottom with content offset succeed, contentOffsetY: \(self.contentOffset.y)")
            }
        }
    }
}

fileprivate class AlbumTitleView: UIControl {
    
    private let titleButton = UIButton()
    
    private let downTrangleView = UIImageView(image: Resources.down_arrow.withRenderingMode(.alwaysTemplate))
    
    func setTitle(_ title: String) {
        titleButton.setTitle(title, for: .normal)
        titleButton.sizeToFit()
    }
    
    func setTitleColor(_ color: UIColor) {
        titleButton.setTitleColor(color, for: .normal)
        downTrangleView.tintColor = color
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        titleButton.isUserInteractionEnabled = false
        titleButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)

        addSubview(titleButton)
        addSubview(downTrangleView)
        
        titleButton.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
        }
        downTrangleView.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleButton.snp.centerY)
            make.right.equalToSuperview()
            make.left.equalTo(titleButton.snp.right).offset(10)
        }
    }
}
