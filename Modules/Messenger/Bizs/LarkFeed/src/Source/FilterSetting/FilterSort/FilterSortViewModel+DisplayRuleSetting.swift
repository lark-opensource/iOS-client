//
//  FilterSortViewModel+DisplayRuleSetting.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/10/11.
//

import Foundation
import LarkOpenFeed
import RustPB
import UniverseDesignToast

extension FilterSortViewModel {
    // 侧栏分组的移动选项到展示/隐藏section过程中,FeedFilterModel需要更新的字段包括style、subTitle、showEditBtn、jumpEnable
    func adjustInfoForMoveItem(_ item: FeedFilterModel, _ toDeleteSection: Bool) -> FeedFilterModel {
        let filterType = item.filterItem.type
        let style: UITableViewCell.EditingStyle = toDeleteSection ? .delete : .insert
        var subTitle: String = ""
        var showEditBtn: Bool = false
        var jumpEnable: Bool = false
        if dependency.enableDisplayRuleSetting(filterType) {
            if filterType == .tag {
                subTitle = ""
                showEditBtn = toDeleteSection
                if let items = try? FeedFilterListSourceFactory.source(for: .tag)?.itemsProvider(userResolver, nil),
                   !items.isEmpty {
                    jumpEnable = true
                }
            } else if let item = msgDisplaySettingMap[filterType] {
                if toDeleteSection {
                    subTitle = item.subTitle
                    showEditBtn = item.editEnable
                    jumpEnable = true
                } else {
                    subTitle = !item.subTitle.isEmpty ? BundleI18n.LarkFeed.Lark_FeedFilter_ShowAllMessagesInFilter_Text : ""
                }
            }
        }

        var moveItem = item
        moveItem.style = style
        moveItem.subTitle = subTitle
        moveItem.showEditBtn = showEditBtn
        moveItem.jumpEnable = jumpEnable
        return moveItem
    }

    func needShowTips(_ filterType: Feed_V1_FeedFilter.TypeEnum) -> Bool {
        guard dependency.enableDisplayRuleSetting(filterType) else { return false }
        if filterType == .tag {
            // 标签分组需要取全部Label数据判断
            let labelRules = dependency.getLabelRules()
            for rule in labelRules {
                //如果内存已有二级标签选项的修改值，则用缓存值判断
                //如果内存没有修改记录，则用默认数据的rule状态判断
                if let map = feedGroupDisplaySettingMap, let itemId = rule.itemId, let item = map[itemId] {
                    if !item.selectedTypes.contains(.showAll) {
                        return true
                    }
                } else {
                    if !rule.selectedTypes.contains(.showAll) {
                        return true
                    }
                }
            }
            return false
        } else if let displayRule = msgDisplaySettingMap[filterType] {
            let defaultOption = displayRule.selectedTypes.contains(.showAll)
            return !defaultOption
        }
        return false
    }

    func pushToMsgDisplaySettingPage(_ filterType: Feed_V1_FeedFilter.TypeEnum) {
        guard dependency.enableDisplayRuleSetting(filterType) else {
            FeedContext.log.info("feedlog/filter/displayRule: \(filterType) not support rule setting")
            return
        }
        if filterType == .tag { // 二级标签分组跳转
            guard let items = try? FeedFilterListSourceFactory.source(for: .tag)?.itemsProvider(userResolver, nil),
                  !items.isEmpty else {
                toastRelay.accept(BundleI18n.LarkFeed.Lark_FeedFilter_NoLabelsCreatedYet_Toast)
                return
            }
            let body = FeedMsgDisplayMoreSettingBody(currentSelectedItemsMap: feedGroupDisplaySettingMap)
            body.selectObservable.subscribe(onNext: { [weak self] itemMap in
                guard let self = self else { return }
                if !self.labelSecondaryRuleChanged {
                    self.labelSecondaryRuleChanged = self.feedGroupDisplaySettingMap?.keys != itemMap.keys ||
                    self.feedGroupDisplaySettingMap?.values.map({ $0.selectedTypes }) != itemMap.values.map({ $0.selectedTypes })
                }
                self.feedGroupDisplaySettingMap = itemMap
            }).disposed(by: disposeBag)
            self.pushViewControllerByBody(body)
            return
        }

        // 一级分组跳转
        let selectedItem = self.msgDisplaySettingMap[filterType] ?? FeedMsgDisplayFilterModel.defaultItem(userResolver: userResolver, type: filterType)
        let filterName = FeedFilterTabSourceFactory.source(for: filterType)?.titleProvider() ?? ""
        let body = FeedMsgDisplaySettingBody(filterName: filterName, currentItem: selectedItem)
        body.selectObservable.subscribe(onNext: { [weak self] item in
            guard let self = self else { return }
            // 用于埋点记录状态
            if !self.displayRuleChanged {
                let originItem = self.msgDisplaySettingMap[item.filterType]
                self.displayRuleChanged = originItem?.selectedTypes != item.selectedTypes
            }
            self.msgDisplaySettingMap[item.filterType] = item
            if let deleteSectionVM = self.itemsMap[.delete], deleteSectionVM.section < self.items.count {
                var newRows: [FeedFilterSortItemProtocol] = []
                for row in deleteSectionVM.rows {
                    if var filterModel = row as? FeedFilterModel, filterModel.filterItem.type == item.filterType {
                        filterModel.subTitle = item.subTitle
                        newRows.append(filterModel)
                    } else {
                        newRows.append(row)
                    }
                }
                var tempItems = self.items
                tempItems[deleteSectionVM.section] = self.refreshDataForSectionVM(deleteSectionVM, newRows)
                self.update(tempItems)
                self.reloadSection(.delete)
            }
        }).disposed(by: disposeBag)
        self.pushViewControllerByBody(body)
    }
}
