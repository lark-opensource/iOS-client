//
//  FeedMainViewController+FeedFilterListViewDelegate.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/5/8.
//

import Foundation
import UniverseDesignTabs
import RustPB
import RxSwift
import RxCocoa

extension FeedMainViewController {
    func didClickFilterItem(_ type: Feed_V1_FeedFilter.TypeEnum, subSelectedId: String?) {
        // feed 列表和 filterTab 切换至对应 type
        changeTab(type, .filterListTabClick)
        filterTabView.filterFixedView?.changeViewTab(type)
    }

    /// 处理团队和标签的二级列表展示逻辑
    func switchListModeIfNeed(_ type: Feed_V1_FeedFilter.TypeEnum) {
        let subSelectedTab = filterTabViewModel.filterFixedViewModel.subSelectedTab
        if let subTab = subSelectedTab, subTab.type != type { return }

        let currentListVC = moduleVCContainerView.currentListVC
        switch type {
        case .team:
            guard let teamVC = currentListVC as? FeedTeamViewController else { return }
            if teamVC.viewModel.subTeamId != subSelectedTab?.tabId {
                teamVC.viewModel.setSubTeamId(subSelectedTab?.tabId)
                teamVC.viewModel.reload()
                if let teamId = subSelectedTab?.tabId, let tid = Int(teamId) {
                    teamVC.viewModel.updateTeamExpanded(tid, isExpanded: true, section: nil)
                }
            }
        case .tag:
            guard let labelVC = currentListVC as? LabelMainListViewController else { return }
            var mode: SwitchModeModule.Mode = .standardMode
            if let selectedTagId = subSelectedTab?.tabId, let tid = Int(selectedTagId) {
                mode = .threeBarMode(tid)
            }
            if mode != labelVC.vm.switchModeModule.mode {
                labelVC.vm.switchModeModule.update(mode: mode)
            }
        @unknown default: break
        }
    }
}
