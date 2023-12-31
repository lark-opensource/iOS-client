//
//  FeedFilterListViewController+Bind.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/3/8.
//

import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import SnapKit
import UniverseDesignToast
import UniverseDesignEmpty
import LarkModel

extension FeedFilterListViewController {
    func bind() {
        viewModel.dependency.filtersUpdateDriver.drive(onNext: { [weak self] in
            guard let self = self else { return }
            self.fullReload()
        }).disposed(by: disposeBag)

        viewModel.dependency.styleService.styleSubject.subscribe(onNext: { [weak self] style in
            guard let self = self else { return }
            FeedContext.log.info("feedlog/threeColumns/style. \(style)")
            let compact: Bool
            if Feed.Feature(userResolver).groupPopOverForPad {
                compact = true
            } else {
                compact = style != .padRegular
            }
            self.updateSubviewLayout(compact)

            // 解决 popover 展开状态下 R/C 没有隐藏的问题
            if Feed.Feature(self.userResolver).groupPopOverForPad,
               self.delegate != nil,
               style == .padCompact {
                self._dismiss(animated: false)
            }
        }).disposed(by: disposeBag)

        viewModel.dependency.selectionObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] selection in
                self?.selectFilterItem(selection)
            }).disposed(by: disposeBag)
    }

    func fullReload() {
        tableView.reloadData()
        self.updatePopoveContentSize()
    }

    func selectFilterItem(_ selection: FeedFilterSelection) {
        viewModel.dependency.currentTab = selection.filterType
        // 判断是一级filter还是二级filter
        let isMultiLevelTab = viewModel.dependency.multiLevelTabs.contains(selection.filterType)

        // 当前所处filter是否需要切换
        if selection == viewModel.currentSelection {
            return
        }

        // 切换filter展示
        if isMultiLevelTab, let secLevelId = selection.secLevelId {
            viewModel.setSubTabId(selection.filterType, subId: secLevelId)
        } else {
            viewModel.dependency.recordSubSelectedTab(subTab: nil)
        }
        tableView.reloadData()
    }
}
