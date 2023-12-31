//
//  FeedMainViewController+SwitchModuleVC.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/31.
//

import Foundation
import UniverseDesignTabs
import RustPB
import RxSwift
import RxCocoa
import LarkOpenFeed

enum FeedChangeTabSource: String {
    // 目前仅作为log使用，记录触发来源的操作日志
    case viewDidLoad           // 页面初始加载
    case filterDataCheck       // 分组数据校验
    case filterListTabClick    // 分组侧栏点击
    case fixedViewTabClick     // 常用分组栏点击
    case fixedViewTabCheck     // 常用分组栏tab校验
    case createTeamTrigger     // 创建团队触发
}

extension FeedMainViewController {
    // 切换新的tab
    func changeTabWithFilterSelectItem(_ newTab: Feed_V1_FeedFilter.TypeEnum) {
        guard let index = self.filterTabViewModel.dataStore.allFiltersDS.firstIndex(where: { $0.type == newTab }) else {
            if newTab == mainViewModel.firstTab {
                self.changeTab(newTab, .filterDataCheck)
                self.filterTabView.filterFixedView?.changeViewTab(newTab)
            }
            return
        }
        self.changeTab(newTab, .filterDataCheck)
        self.filterTabView.filterFixedView?.changeViewTab(newTab)
    }

    func changeTab(_ newTab: Feed_V1_FeedFilter.TypeEnum, _ source: FeedChangeTabSource) {
        let oldTab = mainViewModel.currentFilterType
        if oldTab == newTab {
            switchListModeIfNeed(newTab)
            FeedContext.log.info("feedlog/changeTab/switch. repeatedly switch \(newTab), source: \(source)")
            return
        }
        FeedContext.log.info("feedlog/changeTab/switch/success. old: \(oldTab), new: \(newTab), source: \(source)")
        self.mainViewModel.filterSet.insert(newTab)
        self.moduleVCContainerView.change(oldTab: oldTab, newTab: newTab)
        self.mainViewModel.currentFilterType = newTab
        updateFilterText(newTab)
        switchListModeIfNeed(newTab)
        observeOffsetChange()
    }

    func remove(_ tab: Feed_V1_FeedFilter.TypeEnum) {
        guard self.mainViewModel.filterSet.contains(tab) else {
            let errorMsg = "\(tab) is not exist"
            let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
            FeedExceptionTracker.Filter.changeTab(node: .removeTab, info: info)
            return
        }
        let firstTab = mainViewModel.firstTab
        guard tab != firstTab else {
            FeedContext.log.info("feedlog/changeTab/remove. can't remove firstTab: \(firstTab)")
            return
        }
        FeedContext.log.info("feedlog/changeTab/remove/success. \(tab)")
        self.mainViewModel.filterSet.remove(tab)
        self.moduleVCContainerView.remove(tab)
    }

    private func updateFilterText(_ filter: Feed_V1_FeedFilter.TypeEnum) {
        styleService.currentFilterText.accept(FeedFilterTabSourceFactory.source(for: filter)?.titleProvider() ?? "")
    }
}
