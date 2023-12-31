//
//  WorkPlaceViewController+Drop.swift
//  LarkWorkplace
//
//  Created by lilun.ios on 2021/3/9.
//

import Foundation
/// 拖拽相关
extension WorkPlaceViewController {

    func rawCollectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation: .forbidden)
    }

    func setupDropInteraction() {
        if WorkPlaceScene.supportMutilScene() {
            self.workPlaceCollectionView.dropDelegate = self
        }
    }
}
