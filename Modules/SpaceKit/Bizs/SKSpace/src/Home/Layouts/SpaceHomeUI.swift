//
//  SpaceHomeUI.swift
//  AppDemo
//
//  Created by Weston Wu on 2020/11/25.
//

import UIKit
import SKCommon
import SKFoundation
import RxSwift
import RxRelay
import RxCocoa

public extension SpaceHomeUI {
    enum ReloadAction {
        case fullyReload
        case reloadSections(sections: [Int], animated: Bool)
        case reloadSectionCell(sectionIndex: Int, animated: Bool)
        case update(sectionIndex: Int, inserts: [Int], deletes: [Int], updates: [Int], moves: [(Int, Int)], whenUpdate: () -> Void)
        case getVisableIndexPaths(callback: ([IndexPath]) -> Void)
        case scrollToCell(indexPath: IndexPath, scrollPosition: UICollectionView.ScrollPosition, animated: Bool)
    }

    typealias Action = SpaceSection.Action
}

public struct SpaceHomeUI {
    let headerSection: SpaceHeaderSection?
    private let sections: [SpaceSection]
    private let sectionReloadInput = PublishRelay<(Int, SpaceSection.ReloadAction)>()
    private let reloadInput = PublishRelay<ReloadAction>()
    private let actionInput = PublishRelay<Action>()

    var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }

    var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    private let disposeBag = DisposeBag()

    public init(headerSection: SpaceHeaderSection? = nil, @SpaceSectionBuilder sections: () -> [SpaceSection]) {
        self.init(headerSection: headerSection, sections: sections())
    }

    public init(headerSection: SpaceHeaderSection? = nil, sections: [SpaceSection]) {
        self.headerSection = headerSection
        self.sections = sections
    }
    
    func setup(collectionView: UICollectionView) {
        sections.forEach { section in
            section.setup(collectionView: collectionView)
        }
    }

    func prepare() {
        sectionReloadInput.map { sectionIndex, sectionReloadAction -> ReloadAction in
            switch sectionReloadAction {
            case let .reloadSection(animated):
                return .reloadSections(sections: [sectionIndex], animated: animated)
            case let .reloadSectionCells(animated):
                return .reloadSectionCell(sectionIndex: sectionIndex, animated: animated)
            case let .update(inserts, deletes, updates, moves, willUpdate):
                return .update(sectionIndex: sectionIndex,
                               inserts: inserts,
                               deletes: deletes,
                               updates: updates,
                               moves: moves,
                               whenUpdate: willUpdate)
            case let .getVisableIndices(callback):
                return .getVisableIndexPaths { indexPaths in
                    let sectionPaths = indexPaths
                        .filter { $0.section == sectionIndex }
                    let indices = sectionPaths.map(\.item)
                    let containCellForOtherSections = sectionPaths.count != indexPaths.count
                    callback(indices, containCellForOtherSections)
                }
            case let .scrollToItem(index, scrollPosition, animated):
                return .scrollToCell(indexPath: IndexPath(item: index, section: sectionIndex),
                                     scrollPosition: scrollPosition,
                                     animated: animated)
            }
        }
        .bind(to: reloadInput)
        .disposed(by: disposeBag)

        if let headerSection {
            headerSection.actionSignal.emit(to: actionInput)
                .disposed(by: disposeBag)
            headerSection.prepare()
        }

        for (index, section) in sections.enumerated() {
            section.reloadSignal
                .map { (index, $0) }
                .emit(to: sectionReloadInput)
                .disposed(by: disposeBag)

            section.actionSignal.emit(to: actionInput)
                .disposed(by: disposeBag)

            section.prepare()
        }
    }

    func notifyPullToRefresh() {
        headerSection?.notifyPullToRefresh()
        sections.forEach { $0.notifyPullToRefresh() }
    }

    func notifyPullToLoadMore() {
        headerSection?.notifyPullToLoadMore()
        sections.forEach { $0.notifyPullToLoadMore() }
    }

    func notifyViewDidAppear() {
        headerSection?.notifySectionDidAppear()
        sections.forEach { $0.notifySectionDidAppear() }
    }

    func notifyViewWillDisappear() {
        headerSection?.notifySectionWillDisappear()
        sections.forEach { $0.notifySectionWillDisappear() }
    }
    
    func notifyViewDidLayoutSubviews(hostVCWidth: CGFloat) {
        headerSection?.notifyViewDidLayoutSubviews(hostVCWidth: hostVCWidth)
        sections.forEach { $0.notifyViewDidLayoutSubviews(hostVCWidth: hostVCWidth) }
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension SpaceHomeUI {
    func itemSize(at indexPath: IndexPath, containerWidth: CGFloat) -> CGSize {
        sections[indexPath.section].itemSize(at: indexPath.item, containerWidth: containerWidth)
    }

    func insets(for section: Int, containerWidth: CGFloat) -> UIEdgeInsets {
        sections[section].sectionInsets(for: containerWidth)
    }

    func minimumLineSpacing(at section: Int, containerWidth: CGFloat) -> CGFloat {
        sections[section].minimumLineSpacing(for: containerWidth)
    }

    func minimumInteritemSpacing(at section: Int, containerWidth: CGFloat) -> CGFloat {
        sections[section].minimumInteritemSpacing(for: containerWidth)
    }

    func headerHeight(in section: Int, containerWidth: CGFloat) -> CGFloat {
        sections[section].headerHeight(for: containerWidth)
    }

    func footerHeight(in section: Int, containerWidth: CGFloat) -> CGFloat {
        sections[section].footerHeight(for: containerWidth)
    }
}

// MARK: - UICollectionViewDataSource
extension SpaceHomeUI {

    var numberOfSections: Int { sections.count }

    func numberOfItems(in section: Int) -> Int {
        sections[section].numberOfItems
    }

    func cell(for indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        sections[indexPath.section].cell(at: indexPath, collectionView: collectionView)
    }

    func dragItem(for indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> [UIDragItem] {
        sections[indexPath.section].dragItem(at: indexPath, sceneSourceID: sceneSourceID, collectionView: collectionView)
    }

    @available(iOS 13.0, *)
    func contextMenuConfig(for indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        sections[indexPath.section].contextMenuConfig(at: indexPath, sceneSourceID: sceneSourceID, collectionView: collectionView)
    }

    func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        sections[indexPath.section].supplymentaryElementView(kind: kind, indexPath: indexPath, collectionView: collectionView)
    }
}

// MARK: - UICollectionViewDelegate
extension SpaceHomeUI {
    func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        sections[indexPath.section].didSelectItem(at: indexPath, collectionView: collectionView)
    }

    func notifyDidEndDragging(willDecelerate: Bool) {
        sections.forEach { $0.notifyDidEndDragging(willDecelerate: willDecelerate) }
    }

    func notifyDidEndDecelerating() {
        sections.forEach { $0.notifyDidEndDecelerating() }
    }
    func didEndDisplaying(at indexPath: IndexPath, cell: UICollectionViewCell, collectionView: UICollectionView)
    {
        sections[indexPath.section].didEndDisplaying(at: indexPath, cell: cell, collectionView: collectionView)
    }
}

extension SpaceHomeUI {
    func sectionIndex(for sectionIdentifier: String) -> Int? {
        sections.firstIndex { $0.identifier == sectionIdentifier }
    }
    func section(for sectionIdentifier: String) -> SpaceSection? {
        sections.first { $0.identifier == sectionIdentifier }
    }
}
