//
//  LKAssetsCollectionViewController.swift
//  LarkAssetsBrowser
//
//  Created by 王元洵 on 2021/5/24.
//

import UIKit
import Foundation
import LarkUIKit
import RxCocoa
import RxSwift
import ByteWebImage
import LarkFoundation
import UniverseDesignToast
import UniverseDesignDialog

public struct LKMediaResource {
    public enum MediaType {
        case image
        case video(duration: Int32)
    }

    let data: ImageItemSet
    let type: MediaType
    let key: String
    let canSelect: Bool
    //// 是否有预览权限
    let permissionState: PermissionDisplayState

    public init(data: ImageItemSet,
                type: MediaType,
                key: String,
                canSelect: Bool,
                permissionState: PermissionDisplayState) {
        self.data = data
        self.type = type
        self.key = key
        self.canSelect = canSelect
        self.permissionState = permissionState
    }
}

public protocol LKMediaAssetsDataSource: AnyObject {
    var sectionsDataSource: [String] { get }
    var initialStatusDirver: Driver<InitialStatus> { get set }
    var tableRefreshDriver: Driver<(TableViewFreshType)> { get }
    var currentResourceCount: Int { get }

    func resources(section: Int) -> [LKMediaResource]
    func resource(section: Int, row: Int) -> LKMediaResource
    func fetchInitData()
    func loadMore()
    func didTapSelect()
    func didTapAsset(with key: String,
                     in vc: UIViewController,
                     thumbnail: UIImageView?)
    func getDisplayAsset(with key: String) -> LKDisplayAsset
    func forwardButtonDidTapped(with keys: [String],
                                from sourceVC: UIViewController,
                                isMerge: Bool,
                                completion: (() -> Void)?)
    func deleteButtonDidTapped(with keys: [String], completion: (() -> Void)?)
}

public enum InitialStatus {
    case initialLoading  // 初始化中
    case initialFinish // 初始化完成
    case initialError // 初始化失败
}

// 数据刷新类型
public enum TableViewFreshType {
    case refresh(hasMore: Bool)
    case loadMoreFail(hasMore: Bool)
    case delete(hasMore: Bool)
}

final class LKAssetsCollectionViewController: BaseUIViewController,
                                        UICollectionViewDelegate,
                                        UICollectionViewDataSource {
    private let interitemSpacing: CGFloat = 5
    private let lineSpacing: CGFloat = 5
    private let disposeBag = DisposeBag()
    private let collectionViewMargin: CGFloat = 16
    private let numberImagePerLine: CGFloat = 4
    private let dataSource: LKMediaAssetsDataSource
    private let actionHandler: LKAssetBrowserActionHandler
    private weak var browser: LKAssetBrowserViewController?
    private let minDisplayCount = 30
    private let maxSelectedCellsCount = 9
    private let minSelectedCellsCount = 1

    private var inSelecting = false
    private var allSelectedResources: [String: UIImage?] = [:]

    private lazy var operationPanel = UIStackView()
    private lazy var bottomView = UIView()

    private lazy var selectBarButtonItem = UIBarButtonItem(
        title: BundleI18n.LarkAssetsBrowser.Lark_Legacy_SelectButton,
        style: .plain,
        target: self,
        action: #selector(selectBarButtonItemDidClicked)
    )

    private lazy var cancelBarButtonItem = UIBarButtonItem(
        title: BundleI18n.LarkAssetsBrowser.Lark_Legacy_Cancel,
        style: .plain,
        target: self,
        action: #selector(cancelBarButtonItemDidClicked)
    )

    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let itemSize = (self.view.frame.width - 2 * collectionViewMargin - interitemSpacing * (numberImagePerLine - 1)) / numberImagePerLine
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        layout.minimumInteritemSpacing = interitemSpacing
        layout.minimumLineSpacing = lineSpacing
        layout.sectionHeadersPinToVisibleBounds = true
        layout.headerReferenceSize = CGSize(width: self.view.frame.size.width, height: 50)
        return layout
    }()

    private lazy var imageCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        let hearderIndentifier = String(describing: LKAssetsCollectionHeader.self)
        collectionView.register(LKAssetsCollectionHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: hearderIndentifier)
        let cellIndentifier = String(describing: LKAssetsCollectionCell.self)
        collectionView.register(LKAssetsCollectionCell.self, forCellWithReuseIdentifier: cellIndentifier)
        return collectionView
    }()

    init(dataSource: LKMediaAssetsDataSource,
         actionHandler: LKAssetBrowserActionHandler,
         browser: LKAssetBrowserViewController) {
        self.dataSource = dataSource
        self.actionHandler = actionHandler
        self.browser = browser

        super.init(nibName: nil, bundle: nil)
    }

    private lazy var _initialEmptyDataView: LKAssetsCollectionEmptyDataView = {
        let emptyDataView = LKAssetsCollectionEmptyDataView(frame: .zero)
        emptyDataView.imageView.image = Resources.searchImageInChatInitPlaceHolder
        return emptyDataView
    }()

    private var initialEmptyDataView: LKAssetsCollectionEmptyDataView {
        self.view.bringSubviewToFront(_initialEmptyDataView)
        return _initialEmptyDataView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func listDidAppear() {
        self.updateItemSizeIfNeeded(size: self.view.bounds.size)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.LarkAssetsBrowser.Lark_Legacy_PhotosAndVideos
        self.navigationItem.rightBarButtonItem = selectBarButtonItem

        self.view.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(_initialEmptyDataView)
        _initialEmptyDataView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.view.addSubview(imageCollectionView)
        imageCollectionView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(collectionViewMargin)
            make.right.equalToSuperview().offset(-collectionViewMargin)
            make.top.bottom.equalToSuperview()
        }
        retryLoadingView.retryAction = { [weak self] in
            self?.dataSource.fetchInitData()
        }

        self.view.addSubview(bottomView)
        self.bottomView.isHidden = true
        self.bottomView.backgroundColor = UIColor.ud.bgBase
        self.bottomView.layer.cornerRadius = 12
        self.bottomView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.bottomView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(130)
        }

        self.bottomView.addSubview(operationPanel)
        self.operationPanel.spacing = currentWidth <= 328 ? 24 : 40
        self.operationPanel.addArrangedSubview(
            LKAssetsCollectionOperationItem(
                icon: Resources.mergeForward,
                title: BundleI18n.LarkAssetsBrowser.Lark_Legacy_CombineAndForwardPhotos,
                tapHandler: { [weak self] in
                    self?.mergeForwardButtonDidClicked()
                })
            )
        self.operationPanel.addArrangedSubview(
            LKAssetsCollectionOperationItem(
                icon: Resources.forward,
                title: BundleI18n.LarkAssetsBrowser.Lark_Legacy_OneByOneForwardPhotos,
                tapHandler: { [weak self] in
                    self?.forwardButtonDidClicked()
                })
            )
        self.operationPanel.addArrangedSubview(
            LKAssetsCollectionOperationItem(
                icon: Resources.download,
                title: BundleI18n.LarkAssetsBrowser.Lark_Legacy_DownloadButton,
                tapHandler: { [weak self] in
                    self?.downloadButtonDidClicked()
                })
            )
        self.operationPanel.addArrangedSubview(
            LKAssetsCollectionOperationItem(
                icon: Resources.delete,
                title: BundleI18n.LarkAssetsBrowser.Lark_Legacy_DeleteButton,
                tapHandler: { [weak self] in
                    self?.deleteButtonDidClicked()
                })
            )
        self.operationPanel.distribution = .equalSpacing
        self.operationPanel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(14)
        }

        self.observerDataSource()
        self.dataSource.fetchInitData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // 系统bug，直接返回false无法触发状态栏出现，此时导航栏上移，和主体内容出现一段间距，透出上一页面的内容
    // https://stackoverflow.com/questions/58633830/navbar-overlaps-status-bar-in-ios-13-swift
    var myStatusBarHidden = true
    override var prefersStatusBarHidden: Bool {
        return myStatusBarHidden
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        myStatusBarHidden = false
        setNeedsStatusBarAppearanceUpdate()
    }

    var currentWidth: CGFloat = UIApplication.shared.keyWindow?.bounds.width ?? UIScreen.main.bounds.width
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if currentWidth != view.bounds.width {
            currentWidth = view.bounds.width
            self.operationPanel.spacing = currentWidth <= 328 ? 24 : 40
        }
    }

    private func observerDataSource() {
        self.dataSource
            .initialStatusDirver
            .drive(onNext: { [weak self] (initialStatus) in
                guard let `self` = self else { return }
                switch initialStatus {
                case .initialLoading:
                    self.loadingPlaceholderView.isHidden = false
                case .initialFinish:
                    self.loadingPlaceholderView.isHidden = true
                    self.retryLoadingView.isHidden = true
                    if self.dataSource.sectionsDataSource.isEmpty {
                        self.initialEmptyDataView.isHidden = false
                    } else {
                        self.initialEmptyDataView.isHidden = true
                    }
                case .initialError:
                    self.retryLoadingView.isHidden = false
                }
            }).disposed(by: self.disposeBag)

        self.dataSource
            .tableRefreshDriver
            .drive(onNext: { [weak self] (type) in
                guard let self = self else { return }
                let hasMore: Bool
                let refresh = {
                    self.imageCollectionView.reloadData()
                    self.imageCollectionView.layoutIfNeeded()
                }
                switch type {
                case .refresh(hasMore: let getHasMore):
                    hasMore = getHasMore
                    if self.dataSource.currentResourceCount < self.minDisplayCount
                        && hasMore {
                        self.dataSource.loadMore()
                    } else {
                        refresh()
                    }
                case .loadMoreFail(hasMore: let getHasMore):
                    hasMore = getHasMore
                    UDToast.showFailure(with: BundleI18n.LarkAssetsBrowser.Lark_Legacy_NetworkOrServiceError,
                                        on: self.view)
                case .delete(hasMore: let getHasMore):
                    hasMore = getHasMore
                    refresh()
                }
                if hasMore {
                    self.imageCollectionView.addBottomLoadMoreView { [weak self] in
                        self?.dataSource.loadMore()
                    }
                } else {
                    self.imageCollectionView.removeBottomLoadMore()
                }
            }).disposed(by: self.disposeBag)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            self.updateItemSizeIfNeeded(size: size)
        })
    }

    private func updateItemSizeIfNeeded(size: CGSize) {
        let itemWidth = (size.width - 2 * self.collectionViewMargin
                         - self.interitemSpacing * (self.numberImagePerLine - 1)) / self.numberImagePerLine
        // 如果宽度未变化 / 计算出的结果不符合预期, 不进行布局更新
        if self.layout.itemSize.width == itemWidth || itemWidth <= 0 { return }
        self.layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        self.layout.headerReferenceSize = CGSize(width: size.width, height: 50)
        self.layout.invalidateLayout()
        self.imageCollectionView.reloadData()
    }
    // MARK: - UICollectionViewDelegate, UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.dataSource.sectionsDataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource.resources(section: section).count
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let hearderIndentifier = String(describing: LKAssetsCollectionHeader.self)
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: hearderIndentifier, for: indexPath)
            let section = indexPath.section
            let title = self.dataSource.sectionsDataSource[section]
            (header as? LKAssetsCollectionHeader)?.set(text: title)
            return header
        }
        return UICollectionReusableView(frame: .zero)
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = indexPath.section
        let row = indexPath.row
        let resource = dataSource.resource(section: section, row: row)
        let cellIndentifier = String(describing: LKAssetsCollectionCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIndentifier, for: indexPath)
        if let cell = cell as? LKAssetsCollectionCell {
            cell.set(resource: resource,
                     isBlur: (self.inSelecting && !resource.canSelect) ||
                     (self.allSelectedResources[resource.key] == nil
                      && self.allSelectedResources.count == 9),
                     isSelected: self.allSelectedResources[resource.key] != nil)
            self.inSelecting ? cell.showCheckBox() : cell.hideCheckBox()
            cell.delegate = self
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let resourceKey = self.dataSource.resource(section: indexPath.section,
                                                   row: indexPath.row).key
        let cell = collectionView.cellForItem(at: indexPath) as? LKAssetsCollectionCell

        self.dataSource.didTapAsset(with: resourceKey, in: self, thumbnail: cell?.thumbnail())
    }

    private func setBottomButtonEnable(_ enabled: Bool) {
        self.operationPanel.subviews.forEach {
            if let operationView = $0 as? LKAssetsCollectionOperationItem {
                operationView.setButtonEnable(enabled)
            }
        }
    }

    private func handleForward(isMerge: Bool) {
        guard !self.allSelectedResources.isEmpty else { return }

        dataSource.forwardButtonDidTapped(with: self.allSelectedResources.keys.map { $0 },
                                          from: self,
                                          isMerge: isMerge) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                UDToast.showTips(with: BundleI18n.LarkAssetsBrowser.Lark_Legacy_Success,
                                 on: self.view)
            }
        }
    }

    private func resetSelectedStatus() {
        self.navigationItem.rightBarButtonItem = selectBarButtonItem
        self.inSelecting = false
        self.bottomView.isHidden = true
        self.imageCollectionView.contentInset.bottom = 0
        self.allSelectedResources.removeAll()
        self.imageCollectionView.reloadData()
    }

    @objc
    private func selectBarButtonItemDidClicked() {
        self.dataSource.didTapSelect()
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        self.inSelecting = true
        self.bottomView.isHidden = false
        self.imageCollectionView.contentInset.bottom += self.bottomView.frame.height
        self.setBottomButtonEnable(false)
        self.imageCollectionView.reloadData()
    }

    @objc
    private func cancelBarButtonItemDidClicked() {
        self.resetSelectedStatus()
    }

    private func forwardButtonDidClicked() {
        self.handleForward(isMerge: false)
    }

    private func mergeForwardButtonDidClicked() {
        self.handleForward(isMerge: true)
    }

    private func downloadButtonDidClicked() {
        let assets = self.allSelectedResources.map {
            (self.dataSource.getDisplayAsset(with: $0.key), $0.value)
        }

        guard !assets.isEmpty else { return }

        try? Utils.checkPhotoWritePermission(token: AssetBrowserToken.checkPhotoWritePermission.token) { [weak self] (granted) in
            guard let self = self else { return }
            let resultObservable = self.actionHandler.handleSaveAssets(assets, granted: granted, saveImageCompletion: nil)
            UDToast.showLoading(with: BundleI18n.LarkAssetsBrowser.Lark_Legacy_SavingToast, on: self.view)
            resultObservable.subscribe(onNext: { [weak self] resultArray in
                guard let self = self else { return }
                // 跳过异常情况，actionHandler.handleSaveAssets内会处理，比如：相册权限没有，文件策略不通过等
                guard !resultArray.isEmpty else {
                    UDToast.removeToast(on: self.view)
                    return
                }
                // 获取下载成功的数量
                let succeededCount = resultArray.filter { if case .success = $0 { return true } else { return false } }.count
                // 全部下载成功
                if succeededCount == assets.count {
                    UDToast.showSuccess(with: BundleI18n.LarkAssetsBrowser.Lark_Legacy_SavedToast, on: self.view)
                } else {
                    UDToast.removeToast(on: self.view)
                    // 如果业务方自定义了错误处理方案
                    if !self.actionHandler.saveAssetsCustomErrorHandler(results: resultArray, from: self) {
                        // 使用默认的错误处理方案
                        let message = BundleI18n.LarkAssetsBrowser.Lark_Legacy_NumberDownloadSuccessNumberFail(succeededCount, assets.count - succeededCount)
                        UDToast.showSuccess(with: message, on: self.view)
                    }
                }
                self.resetSelectedStatus()
            }).disposed(by: self.disposeBag)
        }
    }

    private func deleteButtonDidClicked() {
        guard !self.allSelectedResources.isEmpty else { return }

        let alert = UDDialog()
        alert.setTitle(text: BundleI18n.LarkAssetsBrowser.Lark_Legacy_DeleteConfirmationTitle)
        alert.setContent(text: BundleI18n.LarkAssetsBrowser.Lark_Legacy_DeleteConfirmationDesc)
        alert.addCancelButton()
        alert.addPrimaryButton(
            text: BundleI18n.LarkAssetsBrowser.Lark_Legacy_DeleteButton,
            dismissCompletion: { [weak self] in
                guard let self = self else { return }
                self.dataSource
                    .deleteButtonDidTapped(with: self
                                            .allSelectedResources
                                            .keys.map { $0 }) {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            UDToast.showTips(with: BundleI18n.LarkAssetsBrowser.Lark_Legacy_DeletedToast,
                                             on: self.view)
                        }
                    }
                self.setBottomButtonEnable(false)
                self.browser?.updateAssets(with: self.allSelectedResources.keys.map { $0 })
                self.allSelectedResources.removeAll()
            })
        self.present(alert, animated: true)
    }
}

extension LKAssetsCollectionViewController: LKAssetsCollectionCellDelegate {
    func checkBoxDidTapped(in cell: LKAssetsCollectionCell, selected: Bool) {
        guard cell.canSelect else {
            // cell不能选择有两个原因：一个是从post来的资源，一个是资源是无接收权限
            // 只有从post来的资源点击是才会弹toast提示
            if !cell.permissionState.canNotReceive {
                UDToast.showTips(with: BundleI18n.LarkAssetsBrowser.Lark_Legacy_UnableSelectRichTextMedia,
                                 on: self.view)
            }
            return
        }

        if !selected {
            if self.allSelectedResources.isEmpty {
                self.setBottomButtonEnable(true)
            } else if self.allSelectedResources.count == self.maxSelectedCellsCount {
                UDToast.showTips(with: BundleI18n.LarkAssetsBrowser.Lark_Legacy_Max9Items(9),
                                 on: self.view)
                return
            }

            self.allSelectedResources[cell.currentResourceKeyWithThumbnail.0] = cell.currentResourceKeyWithThumbnail.1

            if self.allSelectedResources.count == self.maxSelectedCellsCount {
                self.imageCollectionView.reloadData()
            }
        } else {
            if self.allSelectedResources.count == self.minSelectedCellsCount {
                self.setBottomButtonEnable(false)
            } else if self.allSelectedResources.count == self.maxSelectedCellsCount {
                self.imageCollectionView.reloadData()
            }

            self.allSelectedResources[cell.currentResourceKeyWithThumbnail.0] = nil
        }

        cell.flipCheckBox()
    }
}
