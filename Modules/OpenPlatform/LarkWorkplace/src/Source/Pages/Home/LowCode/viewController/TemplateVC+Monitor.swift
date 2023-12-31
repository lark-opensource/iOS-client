//
//  TemplateVC+Monitor.swift
//  LarkWorkplace
//
//  Created by Shengxy on 2023/6/20.
//

import Foundation
import LarkWorkplaceModel

/// 埋点相关逻辑
extension TemplateViewController: UIScrollViewDelegate {
    /// 用户手指离开屏幕，scrollView 继续滚动的情况
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.didStopScrolling(scrollView: scrollView)
    }

    /// 用户手指离开屏幕，scrollView 停止滚动的情况
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        didStopScrolling(scrollView: scrollView)
    }

    /// ScrollView 停止滚动，上报产品埋点
    func didStopScrolling(scrollView: UIScrollView) {
        guard let collectionView = scrollView as? WPTemplateCollectionView else { return }
        reportBlockExpose(collectionView: collectionView)
    }

    /// 上报 Block 曝光产品埋点，由小于 70% 到大于 >70% 曝光
    func reportBlockExpose(collectionView: WPTemplateCollectionView) {
        let tabbarHeight: CGFloat = 65
        let exposeRatio = 0.7

        let visibleCellArray = collectionView.visibleCells
        let shouldExposeCellArray: [WorkPlaceCellExposeProtocol] = visibleCellArray.compactMap { cell in
            let containerFrame = CGRect(x: collectionView.frame.origin.x,
                                        y: collectionView.frame.origin.y,
                                        width: collectionView.frame.size.width,
                                        height: collectionView.frame.size.height - tabbarHeight)
            let cellFrame = view.convert(cell.frame, from: collectionView)
            let interRect = cellFrame.intersection(containerFrame)
            if let cell = cell as? WorkPlaceCellExposeProtocol,
               cellFrame.height != 0,
               interRect.height / cellFrame.height > exposeRatio {
                return cell
            }
            return nil
        }

        shouldExposeCellArray.forEach { cell in
            let exposeId = cell.exposeId
            guard !exposeId.isEmpty, !(blockExposeState[exposeId] ?? false) else {
                return
            }
            blockExposeState[exposeId] = true
            cell.didExpose()
        }
    }

    /// 重置曝光 Block 字典
    func resetExposeBlockMap(with groups: [GroupComponent]) {
        blockExposeState = [:]
        groups.forEach { group in
            group.nodeComponents.forEach { nodeComponent in
                guard let blockComponent = nodeComponent as? BlockComponent,
                      let itemId = blockComponent.blockModel?.item.itemId else { return }
                blockExposeState[itemId] = false
            }
        }
    }

    /// 常用组件曝光（常用组件内部由 flag 控制，避免曝光多次）
    func reportFavoriteComponentExpose() {
        workPlaceCollectionView.visibleCells.forEach { [weak self] cell in
            guard let `self` = self else { return }
            guard let indexPath = self.workPlaceCollectionView.indexPath(for: cell),
                  let group = self.groupComponents?[indexPath.section],
                  group.groupType == .CommonAndRecommend else { return }
            group.exposePost()
        }
    }

    /// 上报编辑态点击移除 Block 事件，产品埋点
    func reportRemoveBlockBtnClick(model: BlockModel) {
        context.tracker
            .start(.openplatform_workspace_main_page_click)
            .setClickValue(.remove)
            .setTargetView(.none)
            .setMenuType(.remove)
            .setHost(.template)
            .setFavoriteRemoveType(.block)
            .setValue(model.item.itemId, for: .item_id)
            .setValue(model.item.appId, for: .app_id)
            .setValue(model.item.block?.blockTypeId, for: .block_type_id)
            .setValue(model.scene.itemSubType?.trackIntVal, for: .my_common_type)
            .setValue(initData.id, for: .template_id)
            .post()
    }

    /// 上报编辑态点击移除 ICON 事件，产品埋点
    func reportRemoveIconBtnClick(model: ItemModel, subType: WPTemplateModule.ComponentDetail.Favorite.AppSubType?) {
        let isPureLink = model.item.itemType == .link && model.item.linkURL != nil
        context.tracker
            .start(.openplatform_workspace_main_page_click)
            .setClickValue(.remove)
            .setTargetView(.none)
            .setMenuType(.remove)
            .setHost(.template)
            .setFavoriteRemoveType(isPureLink ? .link : .icon)
            .setValue(model.itemID, for: .item_id)
            .setValue(model.appId, for: .app_id)
            .setValue(subType?.trackIntVal, for: .my_common_type)
            .setValue(initData.id, for: .template_id)
            .post()
    }
}
