//
//  IpadSpaceListSubSectionDelegate.swift
//  SKSpace
//
//  Created by majie.7 on 2023/9/25.
//

import Foundation

class IpadSpaceSubSectionDelegateHelper: SpaceListSectionDelegateProxy {
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
        nil
    }
}
