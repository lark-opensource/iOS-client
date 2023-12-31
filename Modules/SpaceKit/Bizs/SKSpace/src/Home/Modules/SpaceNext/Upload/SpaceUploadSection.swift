//
//  SpaceUploadSection.swift
//  SKSpace
//
//  Created by Weston Wu on 2023/5/24.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import SpaceInterface
import SKInfra
import SKCommon
import SKFoundation
import LarkContainer

private extension SpaceUploadSection {
    static var driveMountPoint: String {
        DocsContainer.shared.resolve(DriveRustRouterBase.self)?.mainMountPointTokenString ?? ""
    }
}

public final class SpaceUploadSection: SpaceSection {
    public var identifier: String { "space-upload-status" }

    public var reloadSignal: Signal<ReloadAction> { reloadInput.asSignal() }
    private let reloadInput = PublishRelay<ReloadAction>()

    public var actionSignal: Signal<Action> { actionInput.asSignal() }
    private let actionInput = PublishRelay<Action>()

    private var uploadStatusItem: DriveStatusItem?
    public var numberOfItems: Int {
        if uploadStatusItem != nil {
            return 1
        } else {
            return 0
        }
    }
    private let uploadHelper: SpaceListDriveUploadHelper
    private let disposeBag = DisposeBag()

    public let userResolver: UserResolver
    private var defaultInsetWidth: CGFloat = 32
    
    public init(userResolver: UserResolver, insetWidth: CGFloat? = nil) {
        self.userResolver = userResolver
        if let insetWidth {
            self.defaultInsetWidth = insetWidth
        }
        uploadHelper = SpaceListDriveUploadHelper(mountToken: Self.driveMountPoint,
                                                  mountPoint: DriveConstants.workspaceMountPoint,
                                                  scene: .workspace,
                                                  identifier: "recent")
    }

    public func prepare() {
        // 建立监听
        uploadHelper.uploadStateChanged
            .observeOn(scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                self.handleUploadStateChanged()
            })
            .disposed(by: disposeBag)
        uploadHelper.setup()
    }

    private func handleUploadStateChanged() {
        let uploadState = uploadHelper.driveListConfig
        if uploadState.isNeedUploading {
            let status: DriveStatusItem.Status = uploadState.failed ? .failed : .uploading
            let count = uploadState.failed ? uploadState.errorCount : uploadState.remainder
            let statusItem = DriveStatusItem(count: count,
                                             total: uploadState.totalCount,
                                             progress: uploadState.progress,
                                             status: status)
            self.uploadStatusItem = statusItem
        } else {
            self.uploadStatusItem = nil
        }
        reloadInput.accept(.reloadSection(animated: true))
    }

    public func notifyPullToRefresh() {

    }

    public func notifyPullToLoadMore() {

    }

    public func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize {
        CGSize(width: containerWidth - defaultInsetWidth, height: 48)
    }

    public func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        .zero
    }

    public func minimumLineSpacing(for containerWidth: CGFloat) -> CGFloat {
        0
    }

    public func minimumInteritemSpacing(for containerWidth: CGFloat) -> CGFloat {
        0
    }

    public func headerHeight(for containerWidth: CGFloat) -> CGFloat {
        0
    }

    public func footerHeight(for containerWidth: CGFloat) -> CGFloat {
        0
    }

    public func setup(collectionView: UICollectionView) {
        collectionView.register(DriveUpdatingCell.self, forCellWithReuseIdentifier: DriveUpdatingCell.reuseIdentifier)
    }

    public func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DriveUpdatingCell.reuseIdentifier, for: indexPath)
        guard let driveCell = cell as? DriveUpdatingCell else {
            assertionFailure()
            return cell
        }
        guard let item = uploadStatusItem else {
            spaceAssertionFailure("item not found when create cell")
            return driveCell
        }
        driveCell.update(item, topOffset: 0)
        return driveCell
    }

    public func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        return UICollectionReusableView()
    }

    public func dragItem(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> [UIDragItem] {
        []
    }

    public func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        actionInput.accept(.showDriveUploadList(folderToken: uploadHelper.mountToken))
    }

    @available(iOS 13.0, *)
    public func contextMenuConfig(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        nil
    }
}
