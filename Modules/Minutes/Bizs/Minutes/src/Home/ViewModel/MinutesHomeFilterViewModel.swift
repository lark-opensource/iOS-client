//
//  MinutesHomeFilterViewModel.swift
//  Minutes
//
//  Created by sihuahao on 2021/7/19.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

class MinutesHomeFilterViewModel {

    var filterInfo: FilterInfo
    var cellsInfo: [FilterCondition] = []
    var homeCellsInfo: [[FilterCondition]] = [[]]

    init(filterInfo: FilterInfo) {
        self.filterInfo = filterInfo
    }

    // disable-lint: magic number
    var viewHeight: Int {
        switch filterInfo.spaceType {
        case .home:
            return filterInfo.isEnabled ? 448 : 426
        case .my, .share:
            return 305
        case .trash:
            return 0
        default:
            return 0
        }
    }
    // enable-lint: magic number

    // disable-lint: long_function
    func configCellInfo() {
        switch filterInfo.spaceType {
        case .home:
            homeCellsInfo = []
            let anyoneCondition = FilterCondition(ownerType: MinutesOwnerType.byAnyone,
                    rankType: MinutesRankType.createTime,
                    schedulerType: MinutesSchedulerType.none,
                    isConditionSelected: filterInfo.ownerType == MinutesOwnerType.byAnyone,
                    isArrowUp: false,
                    hasArrow: false,
                    isBelongTo: true)
            let ownedBymeCondition = FilterCondition(ownerType: MinutesOwnerType.byMe,
                    rankType: MinutesRankType.createTime,
                    schedulerType: MinutesSchedulerType.none,
                    isConditionSelected: filterInfo.ownerType == MinutesOwnerType.byMe,
                    isArrowUp: false,
                    hasArrow: false,
                    isBelongTo: true)
            let shareWithmeCondition = FilterCondition(ownerType: MinutesOwnerType.shareWithMe,
                    rankType: MinutesRankType.createTime,
                    schedulerType: MinutesSchedulerType.none,
                    isConditionSelected: filterInfo.ownerType == MinutesOwnerType.shareWithMe,
                    isArrowUp: false,
                    hasArrow: false,
                    isBelongTo: true)
            homeCellsInfo.append([anyoneCondition, ownedBymeCondition, shareWithmeCondition])
            if filterInfo.rankType == .schedulerExecuteTime && !filterInfo.isEnabled {
                filterInfo.rankType = .createTime
            }
            let recentlyCreateCondition = FilterCondition(ownerType: MinutesOwnerType.recentlyCreate, rankType: MinutesRankType.createTime, schedulerType: MinutesSchedulerType.none, isConditionSelected: filterInfo.rankType == MinutesRankType.createTime, isArrowUp: false, hasArrow: false, isEnabled: true)
            let recentlyOpenCondition = FilterCondition(ownerType: MinutesOwnerType.recentlyOpen, rankType: MinutesRankType.openTime, schedulerType: MinutesSchedulerType.none, isConditionSelected: filterInfo.rankType == MinutesRankType.openTime, isArrowUp: false, hasArrow: false, isEnabled: true)
            let autoDeleteTimeCondition = FilterCondition(ownerType: filterInfo.ownerType, rankType: MinutesRankType.schedulerExecuteTime, schedulerType: MinutesSchedulerType.autoDelete, isConditionSelected: filterInfo.schedulerType == MinutesSchedulerType.autoDelete, isArrowUp: true, hasArrow: true, isEnabled: filterInfo.isEnabled)
            if filterInfo.isEnabled {
                homeCellsInfo.append([recentlyCreateCondition, recentlyOpenCondition, autoDeleteTimeCondition])
            } else {
                homeCellsInfo.append([recentlyCreateCondition, recentlyOpenCondition])
            }
        case .my:
            cellsInfo = []
            let myCreateTime = FilterCondition(ownerType: MinutesOwnerType.byAnyone,
                    rankType: MinutesRankType.createTime,
                    schedulerType: MinutesSchedulerType.none,
                    isConditionSelected: filterInfo.rankType == MinutesRankType.createTime,
                    isArrowUp: arrowStatus(selectedFilterType: filterInfo.rankType,
                            defaultFilterType: MinutesRankType.createTime),
                    hasArrow: filterInfo.rankType == MinutesRankType.createTime)
            let myOpenTime = FilterCondition(ownerType: MinutesOwnerType.byAnyone,
                    rankType: MinutesRankType.openTime,
                    schedulerType: MinutesSchedulerType.none,
                    isConditionSelected: filterInfo.rankType == MinutesRankType.openTime,
                    isArrowUp: arrowStatus(selectedFilterType: filterInfo.rankType,
                            defaultFilterType: MinutesRankType.openTime),
                    hasArrow: filterInfo.rankType == MinutesRankType.openTime)
            let myAutoDeleteTime = FilterCondition(ownerType: MinutesOwnerType.byMe,
                    rankType: MinutesRankType.schedulerExecuteTime,
                    schedulerType: MinutesSchedulerType.autoDelete,
                    isConditionSelected: filterInfo.rankType == MinutesRankType.schedulerExecuteTime,
                    isArrowUp: arrowStatus(selectedFilterType: filterInfo.rankType,
                            defaultFilterType: MinutesRankType.schedulerExecuteTime),
                    hasArrow: filterInfo.rankType == MinutesRankType.schedulerExecuteTime, isEnabled: filterInfo.isEnabled)

            cellsInfo.append(myCreateTime)
            cellsInfo.append(myOpenTime)
            if filterInfo.isEnabled {
                cellsInfo.append(myAutoDeleteTime)
            }
        case .share:
            cellsInfo = []
            let shareShareTime = FilterCondition(ownerType: MinutesOwnerType.byAnyone,
                    rankType: MinutesRankType.shareTime,
                    schedulerType: MinutesSchedulerType.none,
                    isConditionSelected: filterInfo.rankType == MinutesRankType.shareTime,
                    isArrowUp: arrowStatus(selectedFilterType: filterInfo.rankType,
                            defaultFilterType: MinutesRankType.shareTime),
                    hasArrow: filterInfo.rankType == MinutesRankType.shareTime)
            let shareOpenTime = FilterCondition(ownerType: MinutesOwnerType.byAnyone,
                    rankType: MinutesRankType.openTime,
                    schedulerType: MinutesSchedulerType.none,
                    isConditionSelected: filterInfo.rankType == MinutesRankType.openTime,
                    isArrowUp: arrowStatus(selectedFilterType: filterInfo.rankType,
                            defaultFilterType: MinutesRankType.openTime),
                    hasArrow: filterInfo.rankType == MinutesRankType.openTime)
            let shareAutoDeleteTime = FilterCondition(ownerType: MinutesOwnerType.shareWithMe,
                    rankType: MinutesRankType.schedulerExecuteTime,
                    schedulerType: MinutesSchedulerType.autoDelete,
                    isConditionSelected: filterInfo.rankType == MinutesRankType.schedulerExecuteTime,
                    isArrowUp: arrowStatus(selectedFilterType: filterInfo.rankType,
                            defaultFilterType: MinutesRankType.schedulerExecuteTime),
                    hasArrow: filterInfo.rankType == MinutesRankType.schedulerExecuteTime, isEnabled: filterInfo.isEnabled)
            cellsInfo.append(shareShareTime)
            cellsInfo.append(shareOpenTime)
            if filterInfo.isEnabled {
                cellsInfo.append(shareAutoDeleteTime)
            }
        case .trash:
            let trashExpireTime = FilterCondition(ownerType: MinutesOwnerType.byAnyone,
                    rankType: MinutesRankType.expireTime,
                    schedulerType: MinutesSchedulerType.none,
                    isConditionSelected: filterInfo.rankType == MinutesRankType.expireTime,
                    isArrowUp: arrowStatus(selectedFilterType: filterInfo.rankType,
                            defaultFilterType: MinutesRankType.expireTime),
                    hasArrow: filterInfo.rankType == MinutesRankType.expireTime)
            let trashAutoDeleteTime = FilterCondition(ownerType: MinutesOwnerType.byAnyone,
                    rankType: MinutesRankType.schedulerExecuteTime,
                    schedulerType: MinutesSchedulerType.autoDelete,
                    isConditionSelected: filterInfo.rankType == MinutesRankType.schedulerExecuteTime,
                    isArrowUp: arrowStatus(selectedFilterType: filterInfo.rankType,
                            defaultFilterType: MinutesRankType.schedulerExecuteTime),
                    hasArrow: filterInfo.rankType == MinutesRankType.schedulerExecuteTime, isEnabled: filterInfo.isEnabled)
            cellsInfo.append(trashExpireTime)
            if filterInfo.isEnabled {
                cellsInfo.append(trashAutoDeleteTime)
            }
        default:
            cellsInfo = []
        }
    }
    // enable-lint: long_function

    func arrowStatus(selectedFilterType: MinutesRankType, defaultFilterType: MinutesRankType) -> Bool {
        if selectedFilterType == defaultFilterType {
            return filterInfo.asc
        } else {
            return false
        }
    }

    func setConfirmInfo() {
        if filterInfo.spaceType == .home {
            var belongToIsInitial = false
            var sortIsInitial = false
            for item in homeCellsInfo {
                for subItem in item {
                    if subItem.isConditionSelected {
                        if subItem.isBelongTo {
                            filterInfo.ownerType = subItem.ownerType
                        } else {
                            filterInfo.rankType = subItem.rankType
                        }
                        filterInfo.asc = subItem.isArrowUp
                        filterInfo.schedulerType = subItem.schedulerType
                    }
                }
            }
        } else {
            for item in cellsInfo where item.isConditionSelected {
                filterInfo.rankType = item.rankType
                filterInfo.asc = item.isArrowUp
                filterInfo.ownerType = item.ownerType
                if item.schedulerType != .none {
                    filterInfo.schedulerType = item.schedulerType
                }
            }
        }
    }
    
    func setDefaultFilterInfo() {
        switch filterInfo.spaceType {
        case .home:
            filterInfo.ownerType = MinutesOwnerType.byAnyone
            filterInfo.rankType = .createTime
            filterInfo.schedulerType = .none
        case .my:
            filterInfo.rankType = MinutesRankType.createTime
            filterInfo.asc = false
        case .share:
            filterInfo.rankType = MinutesRankType.shareTime
            filterInfo.asc = false
        case .trash:
            filterInfo.rankType = MinutesRankType.expireTime
            filterInfo.asc = false
        default:
            return
        }
    }
}

extension MinutesRankType {

    var title: String {
        switch self {
        case .shareTime:
            return BundleI18n.Minutes.MMWeb_G_SortByShared
        case .createTime:
            return BundleI18n.Minutes.MMWeb_G_SortByCreated
        case .openTime:
            return BundleI18n.Minutes.MMWeb_G_SortByLastOpened
        case .expireTime:
            return BundleI18n.Minutes.MMWeb_G_ByLeftTime
        case .schedulerExecuteTime:
            return BundleI18n.Minutes.MMWeb_G_SortByDeleteTime
        default:
            return ""
        }
    }
}

extension MinutesOwnerType {

    var title: String {
        switch self {
        case .byAnyone:
            return BundleI18n.Minutes.MMWeb_M_Home_OwnedByAnyone_Button
        case .shareWithMe:
            return BundleI18n.Minutes.MMWeb_M_Home_SharedWithMe_Button
        case .byMe:
            return BundleI18n.Minutes.MMWeb_M_Home_OwnedByMe_Button
        case .recentlyCreate:
            return BundleI18n.Minutes.MMWeb_G_RecentCreateShare
        case .recentlyOpen:
            return BundleI18n.Minutes.MMWeb_G_RecentOpen
        default:
            return ""
        }
    }
}

extension MinutesSchedulerType {
    var title: String {
        switch self {
        case .autoDelete:
            return BundleI18n.Minutes.MMWeb_G_AutoDeleteTime
        case .autoDegrade:
            return ""
        default:
            return ""
        }
    }

}

extension MinutesSpaceType {
    // disable-lint: magic number
    var padViewHeight: Int {
        switch self {
        case .home:
            return 236
        case .my, .share:
            return 180
        case .trash:
            return 0
        default:
            return 0
        }
    }
    // enable-lint: magic number
}

struct FilterInfo {
    var spaceType: MinutesSpaceType
    var rankType: MinutesRankType
    var ownerType: MinutesOwnerType
    var schedulerType: MinutesSchedulerType
    var isFilterIconActived: Bool
    var asc: Bool
    var isEnabled: Bool = false
}
