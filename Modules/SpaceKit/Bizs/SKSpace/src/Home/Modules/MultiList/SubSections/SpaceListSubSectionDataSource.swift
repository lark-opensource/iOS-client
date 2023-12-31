//
//  SpaceListSubSectionDataSource.swift
//  SKECM
//
//  Created by Weston Wu on 2021/3/30.
//

import Foundation
import LarkSceneManager
import SKCommon

public protocol SpaceListSectionAutoDataSource: SpaceSectionDataSource {
    var sectionDataSourceHelper: SpaceListSectionDataSourceHelper { get }
}

public extension SpaceListSectionAutoDataSource {

    var numberOfItems: Int { sectionDataSourceHelper.numberOfItems }

    func setup(collectionView: UICollectionView) {
        sectionDataSourceHelper.setup(collectionView: collectionView)
    }

    func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        sectionDataSourceHelper.cell(at: indexPath, collectionView: collectionView)
    }

    func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        sectionDataSourceHelper.supplymentaryElementView(kind: kind, indexPath: indexPath, collectionView: collectionView)
    }

    func dragItem(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> [UIDragItem] {
        sectionDataSourceHelper.dragItem(at: indexPath, sceneSourceID: sceneSourceID, collectionView: collectionView)
    }
}

public protocol SpaceListSectionDataSourceHelper: SpaceSectionDataSource {}

protocol SpaceSubSectionDataSourceDelegate: AnyObject {
    var dataSourceListState: SpaceListSubSection.ListState { get }
    var dataSourceDisplayMode: SpaceListDisplayMode { get }
    var dataSourceCellTrackerModule: PageModule { get }
}

class SpaceSubSectionDataSourceHelper: SpaceListSectionDataSourceHelper {

    private weak var delegate: SpaceSubSectionDataSourceDelegate?

    init(delegate: SpaceSubSectionDataSourceDelegate) {
        self.delegate = delegate
    }

    public var numberOfItems: Int {
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
        collectionView.register(DriveUpdatingCell.self, forCellWithReuseIdentifier: DriveUpdatingCell.reuseIdentifier)
        collectionView.register(DriveGridUploadCell.self, forCellWithReuseIdentifier: DriveGridUploadCell.reuseIdentifier)
        collectionView.register(SpaceListCell.self, forCellWithReuseIdentifier: SpaceListCell.reuseIdentifier)
        collectionView.register(SpaceGridCell.self, forCellWithReuseIdentifier: SpaceGridCell.reuseIdentifier)
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
                return collectionView.dequeueReusableCell(withReuseIdentifier: SpaceListCell.reuseIdentifier, for: indexPath)
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SpaceListCell.reuseIdentifier, for: indexPath)
        guard let listCell = cell as? SpaceListCell else {
            assertionFailure()
            return cell
        }
        let module = delegate?.dataSourceCellTrackerModule ?? .home(.recent)
        let bizParameter = SpaceBizParameter(module: module, entry: item.entry)
        let tracker = SpaceListCellTracker(bizParameter: bizParameter)
        listCell.update(item: item, tracker: tracker)
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
