//
//  SpaceSingleListSection.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/3.
//

import UIKit
import RxSwift
import RxCocoa
import RxRelay
import LarkContainer

// 管理单section的header和footer
public final class SpaceSingleListSection: SpaceSection {
    static let sectionIdentifier: String = "single-list"
    public var identifier: String { "\(Self.sectionIdentifier)-\(subSection.subSectionIdentifier)" }

    private let reloadInput = PublishRelay<ReloadAction>()
    public var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    private let subSection: SpaceListSubSection
    private let disposeBag = DisposeBag()
    private var headerBag = DisposeBag()
    // 是否展示 sectionHeader 右侧的 listTools，特定场景有屏蔽的需求，注意排序选项不受影响
    public let listToolsEnabled: Bool
    
    public let userResolver: UserResolver

    public init(userResolver: UserResolver,
                subSection: SpaceListSubSection,
                listToolsEnabled: Bool = true) {
        self.userResolver = userResolver
        self.subSection = subSection
        self.listToolsEnabled = listToolsEnabled
    }

    public func prepare() {
        subSection.reloadSignal.emit(to: reloadInput).disposed(by: disposeBag)
        subSection.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        subSection.prepare()
        subSection.didShowSubSection()
    }

    public func notifyPullToRefresh() {
        subSection.notifyPullToRefresh()
    }
    public func notifyPullToLoadMore() {
        subSection.notifyPullToLoadMore()
    }
    public func notifySectionDidAppear() {
        subSection.notifySectionDidAppear()
    }
    public func notifySectionWillDisappear() {
        subSection.notifySectionWillDisappear()
    }
    public func notifyViewDidLayoutSubviews(hostVCWidth: CGFloat) {
        subSection.notifyViewDidLayoutSubviews(hostVCWidth: hostVCWidth)
    }
}

extension SpaceSingleListSection: SpaceSectionLayout {
    public func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize {
        subSection.itemSize(at: index, containerWidth: containerWidth)
    }

    public func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        subSection.sectionInsets(for: containerWidth)
    }

    public func minimumLineSpacing(for containerWidth: CGFloat) -> CGFloat {
        subSection.minimumLineSpacing(for: containerWidth)
    }

    public func minimumInteritemSpacing(for containerWidth: CGFloat) -> CGFloat {
        subSection.minimumInteritemSpacing(for: containerWidth)
    }

    public func headerHeight(for containerWidth: CGFloat) -> CGFloat {
        SpaceSubListHeaderView.height
    }

    public func footerHeight(for containerWidth: CGFloat) -> CGFloat {
        0
    }
}

extension SpaceSingleListSection: SpaceSectionDataSource {
    public func dragItem(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> [UIDragItem] {
        subSection.dragItem(at: indexPath, sceneSourceID: sceneSourceID, collectionView: collectionView)
    }

    public var numberOfItems: Int {
        subSection.numberOfItems
    }

    public func setup(collectionView: UICollectionView) {
        subSection.setup(collectionView: collectionView)
        collectionView.register(SpaceSubListHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SpaceSubListHeaderView.reuseIdentifier)
    }

    public func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        subSection.cell(at: indexPath, collectionView: collectionView)
    }

    public func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            assertionFailure()
            return UICollectionReusableView()
        }
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SpaceSubListHeaderView.reuseIdentifier, for: indexPath)
        guard let subSectionHeaderView = headerView as? SpaceSubListHeaderView else {
            assertionFailure()
            return headerView
        }
        subSectionHeaderView.update(title: subSection.subSectionTitle, tools: subSection.listTools)
        subSectionHeaderView.toolBar.isHidden = !listToolsEnabled
        return subSectionHeaderView
    }
}

extension SpaceSingleListSection: SpaceSectionDelegate {
    @available(iOS 13.0, *)
    public func contextMenuConfig(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        subSection.contextMenuConfig(at: indexPath, sceneSourceID: sceneSourceID, collectionView: collectionView)
    }
    public func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        subSection.didSelectItem(at: indexPath, collectionView: collectionView)
    }

    public func notifyDidEndDragging(willDecelerate: Bool) {
        subSection.notifyDidEndDragging(willDecelerate: willDecelerate)
    }
    public func notifyDidEndDecelerating() {
        subSection.notifyDidEndDecelerating()
    }
}
