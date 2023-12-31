//
//  TemplateVC+ActionMenu.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/7/9.
//

import Foundation
import UniverseDesignToast
import EENavigator
import LarkUIKit
import RoundedHUD

/// 操作菜单
extension TemplateViewController: ActionMenuHost {
    var menuFromCollectionView: UICollectionView {
        workPlaceCollectionView
    }
    
    var host: ActionMenuHostType {
        return .template
    }

    func getIndexPath(itemId: String, section: Int) -> IndexPath? {
        return actionMenuTriggerItemIndex[itemId]
    }

    func getWorkPlaceItem(indexPath: IndexPath) -> ItemModel? {
        return iconPathDatas[indexPath]
    }

    func getHeaderHeight(section: Int) -> CGFloat {
        return 0
    }

    /// 模板工作台可以唤起操作菜单的 icon 形态应用，都是在「我的常用」组件内
    /// 这里有一个 icon 形态应用的假设，命名上也没有体现，需要优化
    func isCommonAndRec(section: Int) -> Bool { true }

    func isInRecentlyUsedSubModule(section: Int) -> Bool {
        guard let components = groupComponents, section < components.count,
              let favoriteComponent = components[section] as? CommonAndRecommendComponent,
              favoriteComponent.displaySubModule == .recentlyUsed else {
            return false
        }
        return true
    }

    /// 模板化工作台无「添加常用」操作项
    func addCommon(indexPath: IndexPath, itemId: String) {}

    /// 长按菜单，移除 ICON 形态的常用应用
    func removeCommon(indexPath: IndexPath, itemId: String) {
        handleMenuAction { [weak self] in
            self?.removeCommonApp(indexPath: indexPath)
        }
    }

    /// 菜单点击事件
    func onMenuItemTap(item: ActionMenuItem) {
        Self.logger.info("user tap action menu item \(item.name)")
        var reportMenuType: WorkplaceTrackMenuType = .custom
        var reportTarget: WorkplaceTrackTargetValue = .none
        var shouldPost = true
        // 执行点击事件
        switch item.event {
        case .link:
            if let url = item.schema {
                openTriLink(url: url)
            } else {
                shouldPost = false
                Self.logger.info("action item's shema is empty, no aciton")
            }
        case .tip:
            if let tip = item.disableTip, let hudview = self.view {
                UDToast.showTips(with: tip, on: hudview)
                shouldPost = false
            }
        case .cancelCommon:
            guard let indexPath = actMenuShowManager.targetPath else {
                Self.logger.info("action menu item's data not found, no action")
                return
            }
            reportMenuType = .remove
            removeCommonApp(indexPath: indexPath)
        case .callback:
            item.invokeCallbackEvent()
        case .setting:
            if let url = item.schema {
                handleMenuAction { [weak self] in self?.openTriLink(url: url) }
                reportMenuType = .blockSetting
            } else {
                shouldPost = false
                Self.logger.info("setting item's url is empty, no aciton")
            }
            context.tracker
                .start(.openplatform_workspace_main_page_click)
                .setClickValue(.main_block_content)
                .setTargetView(.openplatform_workspace_editor_applist_view)
                .setValue(initData.id, for: .template_id)
                .post()
        case .console:
            guard let indexPath = actMenuShowManager.targetPath,
                  let cell = menuFromCollectionView.cellForItem(at: indexPath) as? BlockCell else {
                Self.logger.error("console block cell is nil")
                return
            }
            guard let logs = cell.getConsoleLogItems() else {
                Self.logger.warn("console logs is nil")
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
            reportMenuType = .share
            handleMenuAction { [weak self] in self?.shareBlock(item: item) }
        }

        // 产品埋点上报
        if !shouldPost { return }
        let blockModel = getSelectedBlockModel()

        context.tracker
            .start(.openplatform_workspace_main_page_click)
            .setClickValue(.block_menu_item)
            .setTargetView(reportTarget)
            .setMenuType(reportMenuType)
            .setHost(.template)
            .setValue(initData.id, for: .template_id)
            .setValue(blockModel?.blockTypeId, for: .block_type_id)
            .setValue(blockModel?.scene.itemSubType?.trackIntVal, for: .my_common_type)
            .setValue(blockModel?.isInFavoriteComponent, for: .if_my_common)
            .post()
    }

    private func shareBlock(item: ActionMenuItem) {
        dependency.share.shareBlockCard(from: self, shareTaskGenerator: { receivers, leaveMessage in
            if let generator = item.shareTaskGenerator {
                return generator(receivers, leaveMessage)
            } else {
                Self.logger.error("no shareTaskGenerator for share item.")
                return nil
            }
        })
    }

    private func getSelectedBlockModel() -> BlockModel? {
        guard let indexPath = actMenuShowManager.targetPath else { return nil }
        let cellModel = getNodeComponent(at: indexPath) as? BlockComponent
        return cellModel?.blockModel
    }
}
