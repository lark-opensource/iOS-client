//
//  BitableMultiListSectionDependency.swift
//  SKSpace
//
//  Created by ByteDance on 2023/11/26.
//

import Foundation
import SKFoundation
import LarkSceneManager
import SKCommon
import SpaceInterface
import SKUIKit
import SKResource

public protocol BitableMultiListSectionHelperProtocol: SpaceSectionDataSource, SpaceSectionLayout, SpaceSectionDelegate {
    var sectionHelper: BitableMultiListSectionDependency { get }
}

public extension BitableMultiListSectionHelperProtocol {
    //MARK: DataSource转发
    var numberOfItems: Int { sectionHelper.numberOfItems }

    func setup(collectionView: UICollectionView) {
        sectionHelper.setup(collectionView: collectionView)
    }

    func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        sectionHelper.cell(at: indexPath, collectionView: collectionView)
    }

    func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        sectionHelper.supplymentaryElementView(kind: kind, indexPath: indexPath, collectionView: collectionView)
    }

    func dragItem(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> [UIDragItem] {
        sectionHelper.dragItem(at: indexPath, sceneSourceID: sceneSourceID, collectionView: collectionView)
    }
    
    //MARK: layout转发
    func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize {
        sectionHelper.itemSize(at: index, containerWidth: containerWidth)
    }

    func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        sectionHelper.sectionInsets(for: containerWidth)
    }

    func minimumLineSpacing(for containerWidth: CGFloat) -> CGFloat {
        sectionHelper.minimumLineSpacing(for: containerWidth)
    }

    func minimumInteritemSpacing(for containerWidth: CGFloat) -> CGFloat {
        sectionHelper.minimumInteritemSpacing(for: containerWidth)
    }

    func headerHeight(for containerWidth: CGFloat) -> CGFloat {
        sectionHelper.headerHeight(for: containerWidth)
    }

    func footerHeight(for containerWidth: CGFloat) -> CGFloat {
        sectionHelper.footerHeight(for: containerWidth)
    }
    
    //MARK: delegate转发
    func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        sectionHelper.didSelectItem(at: indexPath, collectionView: collectionView)
    }

    func notifyDidEndDragging(willDecelerate: Bool) {
        sectionHelper.notifyDidEndDragging(willDecelerate: willDecelerate)
    }

    func notifyDidEndDecelerating() {
        sectionHelper.notifyDidEndDecelerating()
    }

    func didEndDisplaying(at indexPath: IndexPath, cell: UICollectionViewCell, collectionView: UICollectionView) {
        sectionHelper.didEndDisplaying(at: indexPath, cell: cell, collectionView: collectionView)
    }

    @available(iOS 13.0, *)
    func contextMenuConfig(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        sectionHelper.contextMenuConfig(at: indexPath, sceneSourceID: sceneSourceID, collectionView: collectionView)
    }
}

protocol BitableMultiListSectionHelperDelegate: AnyObject {
    //dataSource
    var dataSourceListState: SpaceListSubSection.ListState { get }
    var dataSourceDisplayMode: SpaceListDisplayMode { get }
    var dataSourceCellTrackerModule: PageModule { get }
    var dataSourceSectionIdentifier: String { get }
    var dataSourceSectionIsActive: Bool { get }
    //layout
    var layoutListState: SpaceListSubSection.ListState { get }
    var layoutDisplayMode: SpaceListDisplayMode { get }
    //common-delegate
    var providerListState: SpaceListSubSection.ListState { get }
    var listViewModel: SpaceListViewModel { get }
    func open(newScene: Scene)
}

public class BitableMultiListSectionDependency: SpaceSectionLayout, SpaceSectionDataSource, SpaceSectionDelegate, BitableMultiListCellDelegate, BitablePlaceHolderCellDelegate {

    //MARK: 属性
    private weak var delegate: BitableMultiListSectionHelperDelegate?
    private weak var currentCollectionView: BitableMultiListCollectionView?
    
    init(delegate: BitableMultiListSectionHelperDelegate) {
        self.delegate = delegate
    }
    
    //MARK: dataSource
    public var numberOfItems: Int {
        guard let listState = delegate?.dataSourceListState else {
            return 0
        }
        var numbers = 0
        switch listState {
        case .empty, .loading, .networkUnavailable, .failure:
            numbers = 1
        case let .normal(items):
            numbers = items.count
        case .none:
            numbers = 0
        }
        return numbers
    }
    
    public func setup(collectionView: UICollectionView) {
        if let view = collectionView as? BitableMultiListCollectionView {
            currentCollectionView = view
        }
        collectionView.register(BitablePlaceHolderCell.self, forCellWithReuseIdentifier: BitablePlaceHolderCell.reuseIdentifier)
        collectionView.register(BitableMultiListCell.self, forCellWithReuseIdentifier: BitableMultiListCell.reuseIdentifier)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: UICollectionViewCell.reuseIdentifier)
    }
    
    public func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        guard let listState = delegate?.dataSourceListState else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableMultiListCell.reuseIdentifier, for: indexPath)
            cell.isUserInteractionEnabled = currentShowStyle() == .fullScreen
            return cell
        }
        switch listState {
        case .loading, .empty, .networkUnavailable, .failure, .none:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BitablePlaceHolderCell.reuseIdentifier, for: indexPath)
            guard let placeHolderCell = cell as? BitablePlaceHolderCell else {
                assertionFailure()
                return cell
            }
            guard let placeHolderType = listState.asPlaceHolderType else {
                assertionFailure()
                return cell
            }
            placeHolderCell.isShowInFullScreen = currentShowStyle() == .fullScreen
            placeHolderCell.update(type: placeHolderType, module: delegate?.dataSourceCellTrackerModule)
            placeHolderCell.snapDelegate = self
            return placeHolderCell
        case let .normal(items):
            guard indexPath.item < items.count else {
                assertionFailure()
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableMultiListCell.reuseIdentifier, for: indexPath)
                cell.isUserInteractionEnabled = currentShowStyle() == .fullScreen
                return cell
            }
            let item = items[indexPath.item]
            let cell =  itemCell(at: indexPath, collectionView: collectionView, item: item)
            cell.isUserInteractionEnabled = currentShowStyle() == .fullScreen
            return cell
        }
    }
    
    func itemCell(at indexPath: IndexPath, collectionView: UICollectionView, item: SpaceListItemType) -> UICollectionViewCell {
        if case let .spaceItem(cellItem) = item  {
            return listCell(at: indexPath, collectionView: collectionView, item: cellItem)
        } else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: UICollectionViewCell.reuseIdentifier, for: indexPath)
        }
    }
    
    private func listCell(at indexPath: IndexPath, collectionView: UICollectionView, item: SpaceListItem) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BitableMultiListCell.reuseIdentifier, for: indexPath)
        guard let listCell = cell as? BitableMultiListCell else {
            assertionFailure()
            return cell
        }
        let module = delegate?.dataSourceCellTrackerModule ?? .home(.recent)
        let bizParameter = SpaceBizParameter(module: module, entry: item.entry)
        let tracker = SpaceListCellTracker(bizParameter: bizParameter)
        listCell.update(item: item, tracker: tracker)
        listCell.snapDelegate = self
        return listCell
    }
    
    public func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        assertionFailure()
        return UICollectionReusableView()
    }
    
    public func dragItem(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> [UIDragItem] {
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
    
    //MARK: layout
    public func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize {
        guard let delegate = delegate else { return .zero }
        let listState = delegate.layoutListState
        switch listState {
        case .loading:
            guard let collectionView = self.currentCollectionView, let layoutConfig = collectionView.layoutConfig else {
                return .zero
            }
            if collectionView.currentShowStyle == .fullScreen {
                return CGSize(width: containerWidth, height: layoutConfig.heightForFullScreenStyle - layoutConfig.heightForSectionHeader)
            } else {
                return CGSize(width: containerWidth, height: layoutConfig.heightForEmbededStyle - layoutConfig.heightForSectionHeader)
            }
        case .empty, .networkUnavailable, .failure, .none:
            guard let collectionView = self.currentCollectionView, let layoutConfig = collectionView.layoutConfig else {
                return .zero
            }
            if collectionView.currentShowStyle == .fullScreen {
                return CGSize(width: containerWidth, height: layoutConfig.heightForFullScreenStyle - layoutConfig.heightForSectionHeader)
            } else {
                return CGSize(width: containerWidth, height: layoutConfig.heightForEmbededStyle - layoutConfig.heightForSectionHeader)
            }
        case let .normal(items):
            guard index < items.count else { return .zero }
            let item = items[index]
            if case .spaceItem(item: _) = item {
                return CGSize(width: containerWidth, height: 60)
            } else {
                return .zero
            }
        }
    }
    
    public func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        guard let delegate = delegate else { return .zero }
        let listState = delegate.layoutListState
        switch listState {
        case .loading, .networkUnavailable, .empty, .failure, .none:
            return .zero
        case .normal:
            return .zero
        }
    }
    
    public func minimumLineSpacing(for containerWidth: CGFloat) -> CGFloat {
        return 0
    }
    
    public func minimumInteritemSpacing(for containerWidth: CGFloat) -> CGFloat {
        return 0
    }
    
    public func headerHeight(for containerWidth: CGFloat) -> CGFloat {
        return 0
    }
    
    public func footerHeight(for containerWidth: CGFloat) -> CGFloat {
        return 0
    }
    
    //MARK: commonDelegate
    public func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let index = indexPath.item
        guard case let .normal(itemTypes) = delegate?.providerListState,
              index < itemTypes.count else {
            return
        }
        let itemType = itemTypes[index]
        delegate?.listViewModel.select(at: index, item: itemType)
    }

    public func notifyDidEndDragging(willDecelerate: Bool) {}

    public func notifyDidEndDecelerating() {}

    public func didEndDisplaying(at indexPath: IndexPath, cell: UICollectionViewCell, collectionView: UICollectionView) {
        if let placeholderCell = cell as? BitablePlaceHolderCell {
            placeholderCell.stopLoading()
        }
    }

    @available(iOS 13.0, *)
    public func contextMenuConfig(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        guard SKDisplay.pad else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) {[weak self, weak collectionView] _ -> UIMenu? in
            guard let provider = self?.delegate else { return nil }
            guard case let .normal(items) = provider.providerListState else { return nil }
            guard indexPath.item < items.count,
                  let cell = collectionView?.cellForItem(at: indexPath) else { return nil }
            let item = items[indexPath.item]
            guard case let .spaceItem(listItem) = item else { return nil }
            guard let actionConfig = provider.listViewModel.contextMenuConfig(for: listItem.entry) else { return nil }
            // slideConfig 的顺序和 contextMenu 相反，需要倒置
            var actions = actionConfig.actions.reversed().compactMap { action -> UIAction? in
                guard let (title, image) = action.actionRepresentation else { return nil }
                return UIAction(title: title, image: image) { _ in
                    actionConfig.handler(cell, action)
                }
            }

            if listItem.entry.type.isSupportNewScene && SceneManager.shared.supportsMultipleScenes {
                let newScene = UIAction(title: BundleI18n.SKResource.CreationMobile_iPad_OpenNewWindow_Button,
                                        image: BundleResources.SKResource.Common.Icon.icon_sepwindow_outlined_20.ud.withTintColor(UIColor.ud.iconN1)) { _ in
                    let scene = Scene.docs.scene(listItem.entry.url.absoluteString,
                                                 title: listItem.entry.name,
                                                 sceneSourceID: sceneSourceID,
                                                 objToken: listItem.entry.objToken,
                                                 docsType: listItem.entry.type,
                                                 createWay: .menuClick)
                    provider.open(newScene: scene)
                }
                if actions.isEmpty {
                    actions.append(newScene)
                } else {
                    // 插在倒数第二个
                    actions.insert(newScene, at: actions.count - 1)
                }
            }
            return UIMenu(children: actions)
        }
    }
    
    //MARK: private
    func currentShowStyle() -> BitableMultiListShowStyle {
        if let collectioView = currentCollectionView {
            return collectioView.currentShowStyle
        }
        return .embeded
    }
    
    func didShowSubSection(_ section: BitableMultiListSubSection) {
         currentCollectionView?.didShowSubSection(section)
    }
    
    func shouldForbibbdenCellSnapShot() -> Bool {
        guard let collectioView = currentCollectionView else {
            return false
        }
        //这里看是否需要添加一个系统判断,低于iOS17系统
        if collectioView.isInAnimation && collectioView.currentShowStyle == .embeded {
            return true
        } else {
            return false
        }
    }
    
    func shouldForbibbdenPlaceHolderCellSnapShot() -> Bool {
        guard let collectioView = currentCollectionView else {
            return false
        }
        if collectioView.isInAnimation && collectioView.currentShowStyle == .embeded {
            return true
        } else {
            return false
        }
    }
}
