//
//  WorkPlaceViewController+ActionMenu.swift
//  LarkWorkplace
//
//  Created by bytedance on 2020/7/22.
//

import Foundation
import RoundedHUD
import EENavigator
import LarkUIKit
import UniverseDesignToast
import Swinject
import UIKit
import LarkNavigator
import LarkWorkplaceModel
import LKCommonsLogging
import RxSwift

// MARK: 实现操作菜单的依赖
extension WorkPlaceViewController: ActionMenuHost {
    // 旧版工作台长按菜单显示排序选项
    var showRankOptionInLongPressMenu: Bool {
        return true
    }
    
    var host: ActionMenuHostType {
        return .normal
    }

    func getIndexPath(itemId: String, section: Int) -> IndexPath? {
        // 检查itemId对应的item的indexPath是否有改变
        if let itemsModel = self.workPlaceUIModel?.getSectionModel(index: section) {
            var targetRow: Int = 0
            for item in itemsModel.getDisplayItems() {
                if itemId == (item.getItemId() ?? "") {
                    break
                }
                targetRow += 1
            }
            if targetRow < itemsModel.getDisplayItemCount() {
                return IndexPath(row: targetRow, section: section)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    func getWorkPlaceItem(indexPath: IndexPath) -> ItemModel? {
        return workPlaceUIModel?.getSectionModel(index: indexPath.section)?
            .getItemAtIndex(index: indexPath.row) as? ItemModel
    }

    func getHeaderHeight(section: Int) -> CGFloat {
        if let sectionModel = workPlaceUIModel?.getSectionModel(index: section) {
            return sectionModel.getHeaderSize(superViewWidth: menuFromCollectionView.bdp_width).height
        } else {
            return 0
        }
    }

    func isCommonAndRec(section: Int) -> Bool {
        guard let sectionModel = workPlaceUIModel?.getSectionModel(index: section) else {
            context.trace.error("SectionModel not found at \(section), event post failed")
            return false
        }
        return sectionModel.type == .favorite
    }

    /// 获取展示菜单的collectionView
    var menuFromCollectionView: UICollectionView {
        workPlaceCollectionView
    }

    /// 菜单点击事件
    func onMenuItemTap(item: ActionMenuItem) {
        context.trace.info("user tap action menu item", additionalData: [
            "name": "\(item.name)",
            "event": "\(item.event)",
            "schema": "\(item.schema ?? "")"
        ])
        // 执行点击事件
        switch item.event {
        case .link, .setting:
            if let url = item.schema {
                openTriLink(url: url)
            } else {
                context.trace.info("action item's shema is empty, no aciton")
            }
        case .tip:
            if let tip = item.disableTip, let hudview = self.view {
                UDToast.showTips(with: tip, on: hudview)
            }
        case .cancelCommon:
            guard let indexPath = actMenuShowManager.targetPath,
                  let sectionModel = workPlaceUIModel?.getSectionModel(index: indexPath.section),
                  let itemId = sectionModel.getItemAtIndex(index: indexPath.row)?.getItemId(),
                  let blockModel = sectionModel.getItemAtIndex(index: indexPath.row)?.getBlockModel() else {
                context.trace.error("action item's itemData not found, no aciton")
                return
            }
            context.tracker
                .start(.appcenter_set_cancel_commonuse)
                .setValue(blockModel.appId, for: .app_id)
                .post()
            removeCommon(indexPath: indexPath, itemId: itemId)
            reportBlockMenuItemTap(menuType: .remove, blockModel: blockModel)
        case .callback:
            item.invokeCallbackEvent()
        case .console:
            guard let indexPath = actMenuShowManager.targetPath,
                  let cell = menuFromCollectionView.cellForItem(at: indexPath) as? BlockCell else {
                context.trace.error("console block cell is nil")
                return
            }
            guard let logs = cell.getConsoleLogItems() else {
                context.trace.warn("console logs is nil")
                return
            }
            let vc = LogConsoleController()
            for log in logs {
                vc.appendLog(logItem: log)
            }
            vc.onLogClear = {
                cell.clearConsoleLogItems()
            }
            vc.wp_modalStyle = .pageUp(heightRatio: 0.75)
            present(vc, animated: true, completion: nil)
        case .blockShare:
            handleMenuAction { [weak self] in self?.shareBlock(item: item)}
            let blockModel = getSelectedBlockModel()
            reportBlockMenuItemTap(menuType: .share, blockModel: blockModel)
        }

        dismissActionMenu()
    }

    private func shareBlock(item: ActionMenuItem) {
        dependency.share.shareBlockCard(from: self, shareTaskGenerator: { [weak self](receivers, leaveMessage) -> Observable<[String]>? in
            if let generator = item.shareTaskGenerator {
                return generator(receivers, leaveMessage)
            } else {
                self?.context.trace.error("no shareTaskGenerator for share item.")
                return nil
            }
        })
    }

    private func getSelectedBlockModel() -> BlockModel? {
        guard let indexPath = actMenuShowManager.targetPath else { return nil }
        let sectionModel = workPlaceUIModel?.getSectionModel(index: indexPath.section)
        let blockModel = sectionModel?.getItemAtIndex(index: indexPath.row)?.getBlockModel()
        return blockModel
    }

    private func reportBlockMenuItemTap(menuType: WorkplaceTrackMenuType, blockModel: BlockModel?) {
        let tracker = context.tracker
            .start(.openplatform_workspace_main_page_click)
            .setClickValue(.block_menu_item)
            .setTargetView(.none)
            .setHost(.old)
            .setMenuType(menuType)
            .setValue(blockModel?.scene.itemSubType?.trackIntVal, for: .my_common_type)
            .setValue(blockModel?.blockTypeId, for: .block_type_id)
            .setValue(blockModel?.isInFavoriteComponent, for: .if_my_common)
        if menuType == .remove {
            // 历史逻辑，后续和 DA 同学确认，该字段是否需要
            tracker.setFavoriteRemoveType(.block)
        }
        tracker.post()
    }

    /// 添加应用为常用应用
    func addCommon(indexPath: IndexPath, itemId: String) {
        guard let model = workPlaceUIModel,
              let sectionModel = workPlaceUIModel?.sectionsList[indexPath.section],
              indexPath.item < sectionModel.getDisplayItemCount() else {
            context.trace.error("ItemModel not found at \(indexPath)")
            return
        }
        model.addCommon(sourcePath: indexPath, itemId: itemId)
        actMenuShowManager.isUILocalChanging = true
        handleMenuAction { [weak self] in
            /// 数据同步后端
            self?.dataManager.addCommonApp(itemIds: [itemId], success: { [weak self] in
                guard let `self` = self else { return }
                self.context.trace.info("add common app success")
                UDToast.showSuccess(
                    with: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_SetFrqSuccessToast,
                    on: self.view
                )
            }, failure: { (error) in
                self?.context.trace.error("add common app failed", error: error)
            })
        }
    }

    /// 移除常用应用
    func removeCommon(indexPath: IndexPath, itemId: String) {
        guard let model = workPlaceUIModel,
              let sectionModel = workPlaceUIModel?.sectionsList[indexPath.section],
              indexPath.item < sectionModel.getDisplayItemCount() else {
            context.trace.error("ItemModel not found at \(indexPath)")
            return
        }
        model.removeCommon(indexPath: indexPath, itemId: itemId)
        actMenuShowManager.isUILocalChanging = true
        handleMenuAction { [weak self] in
            /// 数据同步后端
            self?.dataManager.removeCommonApp(itemId: itemId, success: { [weak self] in
                guard let `self` = self else { return }
                self.context.trace.info("remove common app success")
                UDToast.showSuccess(
                    with: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_RemoveFrqSuccessToast,
                    on: self.view
                )
            }, failure: { (error) in
                self?.context.trace.error("remove common app failed", error: error)
            })
        }
    }
}
