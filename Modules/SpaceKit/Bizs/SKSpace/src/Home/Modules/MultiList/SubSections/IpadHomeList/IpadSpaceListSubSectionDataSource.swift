//
//  IpadSpaceListSubSectionDataSource.swift
//  SKSpace
//
//  Created by majie.7 on 2023/9/22.
//
// nolint: magic number duplicated_code

import Foundation
import LarkSceneManager
import RxRelay
import RxSwift
import RxCocoa
import SKCommon


class IpadSpaceSubSectionDataSourceHelper: SpaceListSectionDataSourceHelper {
    
    private weak var delegate: SpaceSubSectionDataSourceDelegate?
    
    // 第二列不展示owner信息，展示排序时间时不为nil
    private let firstSortTypeRelay: BehaviorRelay<SpaceSortHelper.SortType>?
    private let secondSortTypeRelay: BehaviorRelay<SpaceSortHelper.SortType>?
    
    private var sortTypeRelayValue: (SpaceSortHelper.SortType, SpaceSortHelper.SortType)? {
        guard let firstSortTypeRelay, let secondSortTypeRelay else { return nil }
        return (firstSortTypeRelay.value, secondSortTypeRelay.value)
    }
    
    private let clickAvatorHandler: ((String) -> Void)?
    
    init(delegate: SpaceSubSectionDataSourceDelegate,
         firstSortTypeRelay: BehaviorRelay<SpaceSortHelper.SortType>? = nil,
         secondSortTypeRelay: BehaviorRelay<SpaceSortHelper.SortType>? = nil,
         clickAvatorHandler: ((String) -> Void)? = nil) {
        self.delegate = delegate
        self.firstSortTypeRelay = firstSortTypeRelay
        self.secondSortTypeRelay = secondSortTypeRelay
        self.clickAvatorHandler = clickAvatorHandler
    }
    
    var numberOfItems: Int {
        guard let listState = delegate?.dataSourceListState else { return 0 }
        switch listState {
        case .empty, .loading, .networkUnavailable, .failure:
            return 1
        case let .normal(items):
            return items.count
        case .none:
            return 0
        }
    }
    
    func setup(collectionView: UICollectionView) {
        collectionView.register(SpacePlaceHolderCell.self, forCellWithReuseIdentifier: SpacePlaceHolderCell.reuseIdentifier)
        
        collectionView.register(IpadSpaceListViewCell.self, forCellWithReuseIdentifier: IpadSpaceListViewCell.reuseIdentifier)
        collectionView.register(SpaceGridCell.self, forCellWithReuseIdentifier: SpaceGridCell.reuseIdentifier)
        collectionView.register(DriveUpdatingCell.self, forCellWithReuseIdentifier: DriveUpdatingCell.reuseIdentifier)
        collectionView.register(DriveGridUploadCell.self, forCellWithReuseIdentifier: DriveGridUploadCell.reuseIdentifier)
        
        collectionView.register(SpaceInlineSectionSeperatorCell.self, forCellWithReuseIdentifier: SpaceInlineSectionSeperatorCell.reuseIdentifier)
        collectionView.register(SpaceInlineSectionSeperatorGridCell.self, forCellWithReuseIdentifier: SpaceInlineSectionSeperatorGridCell.reuseIdentifier)
        collectionView.register(SpaceVerticalGridPlaceHolderCell.self, forCellWithReuseIdentifier: SpaceVerticalGridPlaceHolderCell.reuseIdentifier)
    }
    
    func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        guard let listState = delegate?.dataSourceListState else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: SpaceListCell.reuseIdentifier, for: indexPath)
        }
        switch listState {
        case .loading, .empty, .networkUnavailable, .failure, .none:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SpacePlaceHolderCell.reuseIdentifier, for: indexPath)
            guard let placeHolderCell = cell as? SpacePlaceHolderCell else {
                assertionFailure()
                return cell
            }
            guard let placeHolderType = listState.asPlaceHolderType else {
                assertionFailure()
                return cell
            }
            placeHolderCell.update(type: placeHolderType, module: delegate?.dataSourceCellTrackerModule)
            return placeHolderCell
        case let .normal(items):
            guard indexPath.item < items.count else {
                assertionFailure()
                return collectionView.dequeueReusableCell(withReuseIdentifier: IpadSpaceListViewCell.reuseIdentifier, for: indexPath)
            }
            let item = items[indexPath.item]
            return itemCell(at: indexPath, collectionView: collectionView, item: item)
        }
    }
    
    func itemCell(at indexPath: IndexPath, collectionView: UICollectionView, item: SpaceListItemType) -> UICollectionViewCell {
        let displayMode = delegate?.dataSourceDisplayMode ?? .list
        switch item {
        case .gridPlaceHolder:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SpaceVerticalGridPlaceHolderCell.reuseIdentifier, for: indexPath)
            return cell
        case let .inlineSectionSeperator(title):
            switch displayMode {
            case .list:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SpaceInlineSectionSeperatorCell.reuseIdentifier, for: indexPath)
                guard let seperatorCell = cell as? SpaceInlineSectionSeperatorCell else {
                    assertionFailure()
                    return cell
                }
                seperatorCell.update(title: title)
                return seperatorCell
            case .grid:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SpaceInlineSectionSeperatorGridCell.reuseIdentifier, for: indexPath)
                guard let seperatorCell = cell as? SpaceInlineSectionSeperatorGridCell else {
                    assertionFailure()
                    return cell
                }
                seperatorCell.update(title: title)
                return seperatorCell
            }
        case let .driveUpload(item):
            switch displayMode {
            case .grid:
                return driveGridUploadCell(at: indexPath, collectionView: collectionView, item: item)
            case .list:
                return driveUploadCell(at: indexPath, collectionView: collectionView, item: item)
            }
        case let .spaceItem(item):
            switch displayMode {
            case .grid:
                return gridCell(at: indexPath, collectionView: collectionView, item: item)
            case .list:
                return listCell(at: indexPath, collectionView: collectionView, item: item)
            }
        }
    }
    
    private func driveUploadCell(at indexPath: IndexPath, collectionView: UICollectionView, item: DriveStatusItem) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DriveUpdatingCell.reuseIdentifier, for: indexPath)
        guard let driveCell = cell as? DriveUpdatingCell else {
            assertionFailure()
            return cell
        }
        driveCell.update(item)
        return driveCell
    }

    private func driveGridUploadCell(at indexPath: IndexPath, collectionView: UICollectionView, item: DriveStatusItem) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DriveGridUploadCell.reuseIdentifier, for: indexPath)
        guard let driveCell = cell as? DriveGridUploadCell else {
            assertionFailure()
            return cell
        }
        driveCell.update(item: item)
        return driveCell
    }
    
    private func listCell(at indexPath: IndexPath, collectionView: UICollectionView, item: SpaceListItem) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IpadSpaceListViewCell.reuseIdentifier, for: indexPath)
        guard let listCell = cell as? IpadSpaceListViewCell else {
            assertionFailure()
            return cell
        }
        listCell.update(item: item)
        if let sortTypeRelayValue {
            let firstTimeString = item.entry.timeTitleBySortType(sortType: sortTypeRelayValue.0)
            let secondTimeString = item.entry.timeTitleBySortType(sortType: sortTypeRelayValue.1)
            listCell.updateMultiTimeInfo(first: firstTimeString, second: secondTimeString)
        } else {
            listCell.setupAvator(item: item, clickHandler: clickAvatorHandler)
        }
        return listCell
    }

    private func gridCell(at indexPath: IndexPath, collectionView: UICollectionView, item: SpaceListItem) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SpaceGridCell.reuseIdentifier, for: indexPath)
        guard let gridCell = cell as? SpaceGridCell else {
            assertionFailure()
            return cell
        }
        gridCell.update(item: item)
        return gridCell
    }
    
    func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        assertionFailure()
        return UICollectionReusableView()
    }
    
    func dragItem(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> [UIDragItem] {
        guard SceneManager.shared.supportsMultipleScenes else { return [] }
        guard let listState = delegate?.dataSourceListState else { return [] }
        switch listState {
        case .empty, .loading, .networkUnavailable, .failure, .none:
            return []
        case let .normal(items):
            let item = items[indexPath.item]
            switch item {
            case .driveUpload, .inlineSectionSeperator, .gridPlaceHolder: return []
            case .spaceItem(let spaceItem):
                guard spaceItem.entry.type.isSupportNewScene else { return [] }
                let scene = Scene.docs.scene(spaceItem.entry.url.absoluteString,
                                             title: spaceItem.entry.name,
                                             sceneSourceID: sceneSourceID,
                                             objToken: spaceItem.entry.objToken,
                                             docsType: spaceItem.entry.type,
                                             createWay: .drag)
                let activity = SceneTransformer.transform(scene: scene)
                let itemProvider = NSItemProvider()
                itemProvider.registerObject(activity, visibility: .all)
                let dragItem = UIDragItem(itemProvider: itemProvider)
                return [dragItem]
            }
        }
    }
    
}
