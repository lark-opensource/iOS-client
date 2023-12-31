//
//  FolderBrowserViewController.swift
//  LarkFile
//
//  Created by 赵家琛 on 2021/4/8.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import RxCocoa
import RustPB
import LarkUIKit
import LarkCore
import UniverseDesignEmpty
import LarkMessengerInterface
import LarkSDKInterface
import UniverseDesignToast

// 文件管理器路由
protocol FolderBrowserRouter: AnyObject {
    func didSelectFile(key: String, name: String, size: Int64, previewStage: Basic_V1_FilePreviewStage) // 点击文件
    func didSelectFolder(key: String, name: String, size: Int64, previewStage: Basic_V1_FilePreviewStage) // 点击文件夹
    func forwardCopy() // 转发副本
    func goChat() // 跳会话
    func goSearch() // 跳搜索
    func openWithOtherApp() //用其他应用打开
    func buildFolderBrowserViewController(key: String, name: String, size: Int64, firstScreenData: Media_V1_BrowseFolderResponse?) -> FolderBrowserViewController //构建文件夹浏览vc；用于压缩包在线解压后展示文件夹结构
    func onVCStatusChanged(_ vc: BaseFolderBrowserViewController) //sources中VC的状态改变（如果是顶部VC则需要更新navigation的展示状态）
    func getTopVCFileType() -> FileType
}

// 当前层级的父文件夹信息
protocol HierarchyFolderInfoProtocol {
    var key: String { get }
    var name: String { get }
    var size: Int64 { get }
    var copyType: ForwardCopyFromFolderMessageBody.CopyType { get }
}

final class FolderBrowserViewController: BaseFolderBrowserViewController {
    private var listCellWidth: CGFloat?
    private let viewModel: FolderBrowserViewModel
    private let disposeBag = DisposeBag()
    private var dataSource: [RustPB.Media_V1_BrowseFolderResponse.SerResp.BrowseInfo] = [] {
        didSet {
            if dataSource.isEmpty {
                collectionView.isHidden = true
                emptyView.isHidden = false
            } else {
                collectionView.isHidden = false
                emptyView.isHidden = true
            }
        }
    }

    private var isGridStyle: Bool = false {
        didSet {
            var space: CGFloat = 0
            if self.isGridStyle {
                space = FileDisplayInfoUtil.gridCellSpaceWidth(view.bounds.width)
            }
            collectionView.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(space)
                make.right.equalToSuperview().offset(-space)
            }
            self.collectionView.reloadData()
        }
    }
    let viewWillTransitionSubject: PublishSubject<CGSize>
    let loadFristScreenDataSuccess: ((Int64) -> Void)?

    init(viewModel: FolderBrowserViewModel,
         displayTopContainer: Bool = false,
         viewWillTransitionSubject: PublishSubject<CGSize>,
         loadFristScreenDataSuccess: ((Int64) -> Void)? = nil) {
        self.viewModel = viewModel
        self.viewWillTransitionSubject = viewWillTransitionSubject
        self.loadFristScreenDataSuccess = loadFristScreenDataSuccess
        super.init(displayTopContainer: displayTopContainer)
        self.title = viewModel.folderInfo.name
        self.viewModel.pageCount = FileDisplayInfoUtil.maxCellPageCount()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        return flowLayout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.flowLayout)
        collectionView.keyboardDismissMode = .onDrag
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(FolderAndFileBrowserListCell.self,
                                forCellWithReuseIdentifier: FolderAndFileBrowserListCell.cellReuseID)
        collectionView.register(ImageVideoFileBrowserListCell.self,
                                forCellWithReuseIdentifier: ImageVideoFileBrowserListCell.cellReuseID)
        collectionView.register(FolderAndFileBrowserGridCell.self,
                                forCellWithReuseIdentifier: FolderAndFileBrowserGridCell.cellReuseID)
        collectionView.register(ImageVideoFileBrowserGridCell.self,
                                forCellWithReuseIdentifier: ImageVideoFileBrowserGridCell.cellReuseID)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 9, right: 0)
        collectionView.contentInsetAdjustmentBehavior = .never
        self.contentContainer.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        return collectionView
    }()

    private lazy var emptyView: UDEmptyView = {
        let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkFile.Lark_Legacy_PullEmptyResult)
        let emptyView = UDEmptyView(config: UDEmptyConfig(description: desc, type: .noFile))
        emptyView.useCenterConstraints = true
        emptyView.isHidden = true
        self.contentContainer.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview().multipliedBy(0.65)
            make.centerX.equalToSuperview()
        }
        return emptyView
    }()

    @objc
    private func retry() {
        self.retryView.isHidden = true
        self.loadingView.show()
        self.viewModel.loadData()
    }

    private lazy var retryViewLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkFile.Lark_Legacy_LoadFailedRetryTip
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N600
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var retryView: UIView = {
        let retryView = UIView()
        retryView.isHidden = true
        self.contentContainer.addSubview(retryView)
        retryView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let wrapperGuide = UILayoutGuide()
        retryView.addLayoutGuide(wrapperGuide)
        wrapperGuide.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview().multipliedBy(0.7)
            make.left.right.equalToSuperview().inset(44)
        }

        let errorImageView = UIImageView(image: Resources.load_fail)
        retryView.addSubview(errorImageView)
        errorImageView.snp.makeConstraints { (make) in
            make.top.centerX.equalTo(wrapperGuide)
        }

        retryView.addSubview(retryViewLabel)
        retryViewLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(wrapperGuide)
            make.top.equalTo(errorImageView.snp.bottom).offset(11)
            make.bottom.equalTo(wrapperGuide)
        }

        let control = UIControl()
        retryView.addSubview(control)
        control.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        control.addTarget(self, action: #selector(retry), for: .touchUpInside)

        return retryView
    }()

    private lazy var loadingView: CoreLoadingView = {
        let loadingView = CoreLoadingView()
        self.contentContainer.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }
        return loadingView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody
        if let isGrid = try? viewModel.gridSubject.value() {
            self.isGridStyle = isGrid
        }
        self.bindViewModel()
    }

    private func bindViewModel() {

        self.loadingView.show()
        viewModel.dataSourceDriver
            .skip(1)
            .drive(onNext: { [weak self] result in
                guard let self = self else { return }
                self.onDataLoadSuccess(result: result)
                self.retryView.isHidden = true
                self.loadingView.hide()
                self.dataSource = result
                self.collectionView.reloadData()
            }).disposed(by: disposeBag)

        viewModel.hasMoreDriver
            .drive(onNext: { [weak self] (hasMore) in
                self?.stopLoading(hasMore)
            }).disposed(by: disposeBag)

        viewModel.errorDriver
            .drive(onNext: { [weak self] error in
                guard let self = self, self.dataSource.isEmpty else { return }
                self.retryView.isHidden = false
                self.loadingView.hide()
                self.collectionView.isHidden = true
                self.emptyView.isHidden = true
                if let error = error.underlyingError as? APIError {
                    switch error.type {
                    case .staticResourceDeletedByAdmin:
                        if let window = self.view.window {
                            UDToast.showFailure(with: BundleI18n.LarkFile.Lark_IM_ViewOrDownloadFile_FileDeleted_Text, on: window)
                        }
                        self.retryView.isUserInteractionEnabled = false
                        self.retryViewLabel.text = BundleI18n.LarkFile.Lark_IM_ViewOrDownloadFile_FileDeleted_Text
                    default:
                        self.retryView.isUserInteractionEnabled = true
                        self.retryViewLabel.text = BundleI18n.LarkFile.Lark_Legacy_LoadFailedRetryTip
                    }
                }
            }).disposed(by: disposeBag)

        /// 更新样式
        viewModel.gridSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isGrid in
                guard let self = self else { return }
                if self.isGridStyle != isGrid {
                    self.isGridStyle = isGrid
                }
            }).disposed(by: disposeBag)

        viewWillTransitionSubject.subscribe(onNext: { [weak self] toSize in
            self?.updateCollectionViewForSize(toSize)
        }).disposed(by: disposeBag)
        viewModel.loadFirstScreenData()
    }

    private func stopLoading(_ more: Bool) {
        collectionView.endBottomLoadMore()
        if more {
            collectionView.addBottomLoadMoreView { [weak self] in
                self?.viewModel.loadData()
            }
        } else {
            collectionView.removeBottomLoadMore()
        }
    }

    func updateCollectionViewForSize(_ size: CGSize) {
        if isGridStyle {
            let space = FileDisplayInfoUtil.gridCellSpaceWidth(size.width)
            collectionView.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(space)
                make.right.equalToSuperview().offset(-space)
            }
        }
        listCellWidth = size.width
        self.collectionView.reloadData()
    }

    private func onDataLoadSuccess(result: [RustPB.Media_V1_BrowseFolderResponse.SerResp.BrowseInfo]) {
        if self.dataSource.isEmpty,
           !result.isEmpty,
           let fileCount = self.viewModel.allCount {
            self.loadFristScreenDataSuccess?(fileCount)
        }
    }
}

extension FolderBrowserViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.isGridStyle {
            return CGSize(width: FileDisplayInfoUtil.gridCellWidth, height: FileDisplayInfoUtil.gridCellHeight)
        } else {
            return CGSize(width: listCellWidth ?? view.bounds.width, height: FileDisplayInfoUtil.listCellHeight)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return isGridStyle ? 16 : 0
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Ensure that the data source of this collectionView won't be accessed by an indexPath out of range
        guard collectionView.cellForItem(at: indexPath) != nil,
              indexPath.row < dataSource.count else { return }
        collectionView.deselectItem(at: indexPath, animated: false)
        let info = dataSource[indexPath.row]
        switch info.type {
        case .folder:
            self.router?.didSelectFolder(key: info.key, name: info.name, size: info.size, previewStage: info.previewStage)
        case .file:
            self.router?.didSelectFile(key: info.key, name: info.name, size: info.size, previewStage: info.previewStage)
        @unknown default:
            assertionFailure("new type")
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let info = self.dataSource[indexPath.row]
        let image: UIImage?
        switch info.type {
        case .folder:
            image = Resources.icon_folder
        case .file:
            image = LarkCoreUtils.fileLadderIcon(with: info.name, size: CGSize(width: 80, height: 80))
        @unknown default:
            image = nil
            assertionFailure("new type")
        }
        let cell: UICollectionViewCell
        if !info.previewImageKey.isEmpty {
            let cellReuseID = self.isGridStyle ? ImageVideoFileBrowserGridCell.cellReuseID : ImageVideoFileBrowserListCell.cellReuseID
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseID, for: indexPath)
        } else {
            let cellReuseID = self.isGridStyle ? FolderAndFileBrowserGridCell.cellReuseID : FolderAndFileBrowserListCell.cellReuseID
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseID, for: indexPath)
        }
        cell.backgroundColor = UIColor.clear
        if let fileCell = cell as? FileDislayCellProtocol {
            let isVideo = !info.previewImageKey.isEmpty && LarkCoreUtils.isVideoFile(with: info.name)
            fileCell.setContent(
                props: FolderAndFileBrowserCellProps(
                    name: info.name,
                    image: image,
                    ownerName: info.ownerName,
                    size: info.size,
                    createTime: info.createTime,
                    previewImageKey: info.previewImageKey,
                    isVideo: isVideo)
                )
        }
        return cell
    }
}

extension FolderBrowserViewController: HierarchyFolderInfoProtocol {
    var copyType: ForwardCopyFromFolderMessageBody.CopyType {
        return .folder
    }

    var key: String {
        return self.viewModel.folderInfo.key
    }

    var name: String {
        return self.viewModel.folderInfo.name
    }

    var size: Int64 {
        return self.viewModel.folderInfo.size
    }
}
