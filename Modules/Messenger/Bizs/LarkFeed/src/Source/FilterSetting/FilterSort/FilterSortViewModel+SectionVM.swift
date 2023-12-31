//
//  FilterSortViewModel+SectionVM.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/10/11.
//

import UIKit
import LarkUIKit
import Foundation
import LarkMessengerInterface

struct FeedSortSectionVM {
    enum SectionType {
        case unknown
        case filterSwitch
        case commonlyFilters
        case delete
        case insert
        case moreSets
    }
    let type: SectionType
    let headerIdentifier: String
    let headerHeight: CGFloat
    let headerTitle: String
    let headerSubTitle: String
    let footerIdentifier: String
    let footerHeight: CGFloat
    let footerTitle: String
    let section: Int
    let editEnable: Bool
    let rows: [FeedFilterSortItemProtocol]

    init(type: SectionType,
         headerIdentifier: String = "",
         headerHeight: CGFloat = 0.0,
         headerTitle: String = "",
         headerSubTitle: String = "",
         footerIdentifier: String = "",
         footerHeight: CGFloat = 8.0,
         footerTitle: String = "",
         section: Int,
         editEnable: Bool = false,
         rows: [FeedFilterSortItemProtocol]) {
        self.type = type
        self.headerIdentifier = headerIdentifier
        self.headerHeight = headerHeight
        self.headerTitle = headerTitle
        self.headerSubTitle = headerSubTitle
        self.footerIdentifier = footerIdentifier
        self.footerHeight = footerHeight
        self.footerTitle = footerTitle
        self.section = section
        self.editEnable = editEnable
        self.rows = rows
    }
}

extension FilterSortViewModel {
    func createDataSourceItems(_ commonlyUsedFilters: [FilterItemModel],
                               _ usedFilters: [FilterItemModel],
                               _ unAdds: [FilterItemModel]) -> [FeedSortSectionVM] {
        var tempItems: [FeedSortSectionVM] = []

        /// section 1
        if dependency.showCommonlyFilters {
            let sectionItems = createCommonlyFilterSectionItems(commonlyUsedFilters)
            if !sectionItems.isEmpty {
                tempItems.append(FeedSortSectionVM(type: .commonlyFilters,
                                                   headerIdentifier: MultiTitleHeaderView.identifier,
                                                   headerHeight: Cons.commonlyFiltersHeaderHeight,
                                                   headerTitle: BundleI18n.LarkFeed.Lark_IM_FeedFilter_FrequentlyUsedFilter_Title,
                                                   footerHeight: Cons.commonlyFiltersFooterHeight,
                                                   section: tempItems.count,
                                                   rows: sectionItems))
            }
        }

        /// section 2
        do {
            let sectionItems = createDeleteSectionItems(usedFilters)
            let headerTitle = Display.pad ? BundleI18n.LarkFeed.Lark_IM_iPad_AllFilters_Text :
                                            BundleI18n.LarkFeed.Lark_IM_FeedFilter_SidebarFilter_Title
            tempItems.append(FeedSortSectionVM(type: .delete,
                                               headerIdentifier: MultiTitleHeaderView.identifier,
                                               headerHeight: Cons.deleteSectionHeaderHeight,
                                               headerTitle: headerTitle,
                                               headerSubTitle: BundleI18n.LarkFeed.Lark_IM_FeedFilter_Show_Mobile,
                                               section: tempItems.count,
                                               editEnable: true,
                                               rows: sectionItems))
        }

        /// section 3
        do {
            let sectionItems = createInsertSectionItems(unAdds)
            tempItems.append(FeedSortSectionVM(type: .insert,
                                               headerIdentifier: HeaderViewWithTitle.identifier,
                                               headerHeight: Cons.insertSectionHeaderHeight,
                                               headerTitle: BundleI18n.LarkFeed.Lark_IM_FeedFilter_Hide_Mobile,
                                               section: tempItems.count,
                                               editEnable: true,
                                               rows: sectionItems))
        }

        /// section 4
        if dependency.showMoreSetsItem {
            let sectionItems = createMoreSetSectionItems()
            if !sectionItems.isEmpty {
                tempItems.append(FeedSortSectionVM(type: .moreSets,
                                                   headerHeight: 8,
                                                   section: tempItems.count,
                                                   rows: sectionItems))
            }
        }

        return tempItems
    }

    func createFilterSwitchSectionItems() -> [FeedFilterSortItemProtocol] {
        var sectionItems: [FeedFilterSortItemProtocol] = []
        sectionItems.append(FeedFilterEditModel(
            cellIdentifier: FilterEditCell.lu.reuseIdentifier,
            title: BundleI18n.LarkFeed.Lark_Feed_MessageFilter,
            status: isSwitchOpen,
            switchEnable: true,
            switchHandler: { [weak self] (isOn) in
                guard let self = self else { return }
                var selectedItems: [FeedFilterSortItemProtocol] = []
                if let sectionVM = self.itemsMap[.delete], sectionVM.section < self.items.count {
                    selectedItems = sectionVM.rows
                }

                if !selectedItems.isEmpty {
                    self.isSwitchOpen = isOn
                    self.hudShowRelay.accept(isOn)
                    FeedTeaTrack.trackFilterEditOpen(status: isOn)
                    FeedTracker.GroupEdit.Click.Toggle()
                    self.setNeedSwitch()
                }
            }
        ))
        return sectionItems
    }

    func createCommonlyFilterSectionItems(_ commonlyUsedFilters: [FilterItemModel]) -> [FeedFilterSortItemProtocol] {
        var sectionItems: [FeedFilterSortItemProtocol] = []
        var filterItems: [FeedCommonlyFilterItem] = []
        for filterItem in commonlyUsedFilters {
            let canEditCell = !commonlyEditBlackList.contains(filterItem.type)
            filterItems.append(FeedCommonlyFilterItem(
                filterItem: filterItem,
                editEnable: canEditCell
            ))
        }
        sectionItems.append(FeedCommonlyFilterModel(
            cellIdentifier: FilterCommonlyCell.lu.reuseIdentifier,
            maxLimitWidth: maxLimitWidth,
            filterItems: filterItems,
            tapHandler: { [weak self] type in
                self?.deleteCommonlyUsedFilter(type)
            },
            addHandler: { [weak self] in
                self?.selectCommonlyUsedFilter()
            }
        ))
        return sectionItems
    }

    func createDeleteSectionItems(_ usedFilters: [FilterItemModel]) -> [FeedFilterSortItemProtocol] {
        var sectionItems: [FeedFilterSortItemProtocol] = []
        for filterItem in usedFilters {
            let canEditCell = !editBlackList.contains(filterItem.type)
            let canMoveCell = !filterMoveBlackList.contains(filterItem.type)
            var subTitle: String = ""
            var showEditBtn: Bool = false
            var jumpEnable: Bool = false
            if dependency.enableDisplayRuleSetting(filterItem.type) {
                if filterItem.type == .tag {
                    subTitle = ""
                    showEditBtn = true
                    if let items = try? FeedFilterListSourceFactory.source(for: .tag)?.itemsProvider(userResolver, nil),
                       !items.isEmpty {
                        jumpEnable = true
                    }
                } else {
                    let item = msgDisplaySettingMap[filterItem.type] ?? FeedMsgDisplayFilterModel.defaultItem(userResolver: userResolver, type: filterItem.type)
                    subTitle = item.subTitle
                    showEditBtn = item.editEnable
                    jumpEnable = true
                }
            }
            sectionItems.append(FeedFilterModel(
                cellIdentifier: canEditCell ? FilterCell.lu.reuseIdentifier : FilterRemoveDisableCell.lu.reuseIdentifier,
                filterItem: filterItem,
                title: filterItem.name,
                subTitle: subTitle,
                style: .delete,
                editEnable: canEditCell,
                moveEnable: canMoveCell,
                jumpEnable: jumpEnable,
                showEditBtn: showEditBtn,
                tapHandler: { [weak self] in
                    self?.pushToMsgDisplaySettingPage(filterItem.type)
                }
            ))
        }
        return sectionItems
    }

    func createInsertSectionItems(_ unAdds: [FilterItemModel]) -> [FeedFilterSortItemProtocol] {
        var sectionItems: [FeedFilterSortItemProtocol] = []
        for filterItem in unAdds {
            let canEditCell = !editBlackList.contains(filterItem.type)
            let canMoveCell = !filterMoveBlackList.contains(filterItem.type)
            var subTitle: String = ""
            if dependency.enableDisplayRuleSetting(filterItem.type) {
                if filterItem.type == .tag {
                    subTitle = ""
                } else if let item = msgDisplaySettingMap[filterItem.type] {
                    // 特化逻辑：若有副标题则展示默认文案
                    subTitle = !item.subTitle.isEmpty ? BundleI18n.LarkFeed.Lark_FeedFilter_ShowAllMessagesInFilter_Text : ""
                }
            }
            sectionItems.append(FeedFilterModel(
                cellIdentifier: canEditCell ? FilterCell.lu.reuseIdentifier : FilterRemoveDisableCell.lu.reuseIdentifier,
                filterItem: filterItem,
                title: filterItem.name,
                subTitle: subTitle,
                style: .insert,
                editEnable: canEditCell,
                moveEnable: canMoveCell,
                tapHandler: { [weak self] in
                    self?.pushToMsgDisplaySettingPage(filterItem.type)
                }
            ))
        }
        return sectionItems
    }

    func createMoreSetSectionItems() -> [FeedFilterSortItemProtocol] {
        var sectionItems: [FeedFilterSortItemProtocol] = []
        sectionItems.append(FeedFilterMoreSetsModel(
            cellIdentifier: FeedFilterMoreSetsCell.lu.reuseIdentifier,
            title: BundleI18n.LarkFeed.Lark_Feed_UpSettings,
            tapHandler: { [weak self] in
                let body = FeedFilterSettingBody(source: .fromMine, showMuteFilterSetting: true)
                self?.pushViewControllerByBody(body)
            }
        ))
        return sectionItems
    }

    // 交换数组中的数据
    func exchange(from: Position, to: Position) -> [FeedSortSectionVM] {
        var newArray: [FeedSortSectionVM] = items
        let fromSection = from.section
        let fromRow = from.row
        let toSection = to.section
        let toRow = to.row
        guard fromSection < newArray.count, toSection < newArray.count,
              let deleteSectionVM = itemsMap[.delete], deleteSectionVM.section < items.count else { return newArray }
        let sectionVM = newArray[fromSection]
        guard fromRow < sectionVM.rows.count else { return newArray }
        guard let item = sectionVM.rows[fromRow] as? FeedFilterModel else { return newArray }
        let moveItem = adjustInfoForMoveItem(item, toSection == deleteSectionVM.section)

        var deleArray = sectionVM.rows
        deleArray.remove(at: fromRow)
        newArray[fromSection] = refreshDataForSectionVM(sectionVM, deleArray)

        let toSectionVM = newArray[toSection]
        var addArray = toSectionVM.rows
        addArray.insert(moveItem, at: toRow)
        newArray[toSection] = refreshDataForSectionVM(toSectionVM, addArray)
        return newArray
    }

    func updateItem(from: Position) -> [FeedSortSectionVM] {
        var newArray: [FeedSortSectionVM] = items
        let fromSection = from.section
        let fromRow = from.row
        guard fromSection < newArray.count,
              let deleteSectionVM = itemsMap[.delete],
              deleteSectionVM.section < items.count else {
            return newArray
        }
        let sectionVM = newArray[fromSection]
        guard fromRow < sectionVM.rows.count else { return newArray }
        guard let item = sectionVM.rows[fromRow] as? FeedFilterModel else { return newArray }
        let moveItem = adjustInfoForMoveItem(item, fromSection == deleteSectionVM.section)
        var rows = sectionVM.rows
        rows[fromRow] = moveItem
        newArray[fromSection] = refreshDataForSectionVM(sectionVM, rows)
        return newArray
    }

    func refreshDataForSectionVM(_ sectionVM: FeedSortSectionVM, _ newRows: [FeedFilterSortItemProtocol]) -> FeedSortSectionVM {
        return FeedSortSectionVM(type: sectionVM.type,
                                 headerIdentifier: sectionVM.headerIdentifier,
                                 headerHeight: sectionVM.headerHeight,
                                 headerTitle: sectionVM.headerTitle,
                                 headerSubTitle: sectionVM.headerSubTitle,
                                 footerIdentifier: sectionVM.footerIdentifier,
                                 footerHeight: sectionVM.footerHeight,
                                 footerTitle: sectionVM.footerTitle,
                                 section: sectionVM.section,
                                 editEnable: sectionVM.editEnable,
                                 rows: newRows)
    }

    enum Cons {
        static let commonlyFiltersHeaderHeight: CGFloat = 50.0
        static let commonlyFiltersFooterHeight: CGFloat = 16.0
        static let deleteSectionHeaderHeight: CGFloat = 78.0
        static let insertSectionHeaderHeight: CGFloat = 28.0
    }
}
