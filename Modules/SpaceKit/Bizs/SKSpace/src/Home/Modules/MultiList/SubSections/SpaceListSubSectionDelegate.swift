//
//  SpaceListSubSectionDelegate.swift
//  SKECM
//
//  Created by Weston Wu on 2021/4/20.
//

import UIKit
import SKUIKit
import SKResource
import LarkSceneManager

public protocol SpaceListSectionCommonDelegate: SpaceSectionDelegate {
    var sectionDelegateProxy: SpaceListSectionDelegateProxy { get }
}

public extension SpaceListSectionCommonDelegate {
    func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        sectionDelegateProxy.didSelectItem(at: indexPath, collectionView: collectionView)
    }

    func notifyDidEndDragging(willDecelerate: Bool) {
        sectionDelegateProxy.notifyDidEndDragging(willDecelerate: willDecelerate)
    }

    func notifyDidEndDecelerating() {
        sectionDelegateProxy.notifyDidEndDecelerating()
    }
    
    func didEndDisplaying(at indexPath: IndexPath, cell: UICollectionViewCell, collectionView: UICollectionView) {
        sectionDelegateProxy.didEndDisplaying(at: indexPath, cell: cell, collectionView: collectionView)
    }

    @available(iOS 13.0, *)
    func contextMenuConfig(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        sectionDelegateProxy.contextMenuConfig(at: indexPath, sceneSourceID: sceneSourceID, collectionView: collectionView)
    }
}

public protocol SpaceListSectionDelegateProxy: SpaceSectionDelegate {}

protocol SpaceSubSectionDelegateProvider: AnyObject {
    var providerListState: SpaceListSubSection.ListState { get }
    var listViewModel: SpaceListViewModel { get }
    func open(newScene: Scene)
}

class SpaceSubSectionDelegateHelper: SpaceListSectionDelegateProxy {

    private weak var provider: SpaceSubSectionDelegateProvider?

    init(provider: SpaceSubSectionDelegateProvider) {
        self.provider = provider
    }

    func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let index = indexPath.item
        guard case let .normal(itemTypes) = provider?.providerListState,
              index < itemTypes.count else {
            return
        }
        let itemType = itemTypes[index]
        provider?.listViewModel.select(at: index, item: itemType)
    }

    func notifyDidEndDragging(willDecelerate: Bool) {}

    func notifyDidEndDecelerating() {}

    func didEndDisplaying(at indexPath: IndexPath, cell: UICollectionViewCell, collectionView: UICollectionView) {
        if let placeholderCell = cell as? SpacePlaceHolderCell {
            placeholderCell.stopLoading()
        }
    }

    @available(iOS 13.0, *)
    func contextMenuConfig(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        guard SKDisplay.pad else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) {[weak self, weak collectionView] _ -> UIMenu? in
            guard let provider = self?.provider else { return nil }
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
}
