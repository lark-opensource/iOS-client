//
//  MoreAppListViewController+UICollectionViewDragDelegate.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/5/28.
//

import LKCommonsLogging
import LarkUIKit
import EENavigator
import Foundation
import Swinject
import RxSwift
import LarkAccountInterface
import LarkAlertController
import LarkOPInterface
import LarkMessengerInterface
import LarkAppLinkSDK
import RustPB
import LarkRustClient
import LarkModel
import EEMicroAppSDK
import RoundedHUD

// MARK: - UICollectionViewDragDelegate
/// 拖拽实现参考：https://stackoverflow.com/questions/12257008/using-long-press-gesture-to-reorder-cells-in-tableview/57225766#57225766
extension MoreAppListViewController {
    func _collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        /// 只允许外露常用列表可拖动
        if indexPath.section != MoreAppListSectionMode.externalList.rawValue {
            return []
        }
        // 常用个数大于1时，才可拖动
        guard let model = viewModel else {
            GuideIndexPageVCLogger.error("GuideIndexPageView viewModel is empty, show page failed")
            return []
        }
        if model.externalItemListCountGreaterThan1 == false  {
            return []
        }
        return [UIDragItem(itemProvider: NSItemProvider())]
    }

    /// Controls whether the drag session is restricted to the source application.
    func _collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        return true
    }

    /// 拖拽时隐藏背景色
    func _collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return nil
        }
        let parameters = UIDragPreviewParameters()
        parameters.visiblePath = UIBezierPath(
            roundedRect: cell.bounds,
            cornerRadius: MoreAppCollectionViewCell.contentViewCornerRadius
        )
        return parameters
    }
}

// MARK: - UICollectionViewDropDelegate
extension MoreAppListViewController {
    func _collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard session.localDragSession != nil, session.items.count == 1 else {
            // Drag originated from the same app.
            // Accept only one drag item.
            return UICollectionViewDropProposal(operation: .cancel, intent: .unspecified)
        }
        /// 只允许外露常用列表可拖动
        if destinationIndexPath?.section == MoreAppListSectionMode.externalList.rawValue {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .cancel, intent: .unspecified)
    }

    func _collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        if let destinationIndexPath = coordinator.destinationIndexPath, coordinator.proposal.operation == .move {
            reorderItems(coordinator: coordinator, destinationIndexPath:destinationIndexPath, collectionView: collectionView)
        }
    }

    private func reorderItems(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        let items = coordinator.items
        if items.count == 1, let item = items.first,
           let sourceIndexPath = item.sourceIndexPath {
            collectionView.performBatchUpdates {
                // 先更新数据，再刷新collectionView
                self.reorderCollectionView(collectionView, moveItemAt: sourceIndexPath, to: destinationIndexPath)
                collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
            }
            // 以动画形式移动cell
            coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        }
    }

    /// 操作添加到常用后，支持拖拽排序，当卡片移动到目标卡片 50% 的位置时，完成位移
    func reorderCollectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let model = viewModel else {
            GuideIndexPageVCLogger.error("GuideIndexPageView viewModel is empty, move row failed")
            return
        }
        GuideIndexPageVCLogger.info("moveRowAt sourceIndexPath: \(sourceIndexPath), to destinationIndexPath: \(destinationIndexPath)")
        // 无顺序变化时，直接不处理
        if sourceIndexPath == destinationIndexPath { return }
        let sourceRow = sourceIndexPath.row
        let destinationRow = destinationIndexPath.row
        guard var collection = model.data.externalItemListModel.externalItemList, collection.count > sourceRow, collection.count >= destinationRow else {
            return
        }
        let originCollection = collection
        let moveObject = collection[sourceRow]
        collection.remove(at: sourceRow)
        collection.insert(moveObject, at: destinationRow)
        reorderDataAndRefreshUI(newExternalItemList: collection, shouldReloadData: false)
        updateRemoteExternalItemListData(externalItemList: collection) { [weak self] (isSuccess) in
            guard let `self` = self else { return }
            if !isSuccess {
                // 报错提醒：后端请求失败或网络出现问题时，显示报错提醒，并且页面刷新恢复到失败前的状态
                self.reorderDataAndRefreshUI(newExternalItemList: originCollection, shouldReloadData: false)
                self.collectionView.moveItem(at: destinationIndexPath, to: sourceIndexPath)
                // move后需要reload，否则移动前后的cell视图会不同步
                self.collectionView.reloadItems(at: [sourceIndexPath, destinationIndexPath])
            }
        }
    }
}
