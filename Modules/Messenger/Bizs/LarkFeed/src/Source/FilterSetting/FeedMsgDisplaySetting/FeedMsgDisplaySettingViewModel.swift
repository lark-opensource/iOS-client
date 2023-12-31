//
//  FeedMsgDisplaySettingViewModel.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/20.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import RustPB
import LarkContainer

struct FeedMsgDisplaySectionVM {
    let headerIdentifier: String
    let headerHeight: CGFloat
    let headerTitle: String
    let headerSubTitle: String
    let footerIdentifier: String
    let footerHeight: CGFloat
    let footerTitle: String
    let section: Int
    let editEnable: Bool
    let rows: [FeedMsgDisplayCellItem]

    init(headerIdentifier: String = "",
         headerHeight: CGFloat = 0.0,
         headerTitle: String = "",
         headerSubTitle: String = "",
         footerIdentifier: String = "",
         footerHeight: CGFloat = 8.0,
         footerTitle: String = "",
         section: Int,
         editEnable: Bool = false,
         rows: [FeedMsgDisplayCellItem]) {
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

final class FeedMsgDisplaySettingViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    private let dependency: FeedMsgDisplaySettingDependency
    private let showNewSelectedTypes: [FeedMsgDisplayItemType] = [.showNew, .showAllNew, .showAtMeMentions, .showAtAllMentions, .showStarredContacts]
    private let showNewSelectedTypesByOpt: [FeedMsgDisplayItemType] = [.showNew, .showAtMeMentions, .showAtAllMentions, .showStarredContacts]
    var sections: [FeedMsgDisplaySectionVM] = []

    private let reloadDataSubject = ReplaySubject<Void>.create(bufferSize: 1)
    var reloadDataDriver: Driver<Void> {
        return reloadDataSubject.asDriver(onErrorJustReturn: ())
    }

    var hudShowRelay = BehaviorRelay<String>(value: "")
    var hudShowDriver: Driver<String> {
        return hudShowRelay.asDriver().skip(1)
    }

    init(userResolver: UserResolver, dependency: FeedMsgDisplaySettingDependency) {
        self.userResolver = userResolver
        self.dependency = dependency
        loadOptions()
    }

    // MARK: - Private
    private func loadOptions() {
        let selectedTypes = dependency.accessMsgDisplayFilterItem().selectedTypes
        let rows = createRows(selectedTypes)
        reload(rows)
    }

    private func createRows(_ selectedTypes: [FeedMsgDisplayItemType]) -> [FeedMsgDisplayCellItem] {
        if Feed.Feature(userResolver).groupSettingOptEnable {
            return createRowsByOpt(selectedTypes)
        } else {
            return createRowsByDefault(selectedTypes)
        }
    }

    private func createRowsByDefault(_ selectedTypes: [FeedMsgDisplayItemType]) -> [FeedMsgDisplayCellItem] {
        var rows: [FeedMsgDisplayCellItem] = []
        let selectAll = selectedTypes.contains(.showAll)
        let selectNone = selectedTypes.contains(.showNone)
        let selectNew = !selectAll && !selectNone
        let selectAllNew = selectedTypes.contains(.showAllNew)
        rows.append(FeedMsgDisplayCellViewModel(userResolver: userResolver, type: .showAll, isSelected: selectAll))
        rows.append(FeedMsgDisplayCellViewModel(userResolver: userResolver, type: .showNew, isSelected: selectNew))
        if selectNew {
            rows.append(FeedMsgDisplayCellViewModel(userResolver: userResolver, type: .showAllNew,
                                                    isSelected: selectAllNew,
                                                    isCheckBox: true))
            rows.append(FeedMsgDisplayCellViewModel(userResolver: userResolver, type: .showAtMeMentions,
                                                    isSelected: selectAllNew || selectedTypes.contains(.showAtMeMentions),
                                                    editEnable: !selectAllNew,
                                                    isCheckBox: true))
            rows.append(FeedMsgDisplayCellViewModel(userResolver: userResolver, type: .showAtAllMentions,
                                                    isSelected: selectAllNew || selectedTypes.contains(.showAtAllMentions),
                                                    editEnable: !selectAllNew,
                                                    isCheckBox: true))
            rows.append(FeedMsgDisplayCellViewModel(userResolver: userResolver, type: .showStarredContacts,
                                                    isSelected: selectAllNew || selectedTypes.contains(.showStarredContacts),
                                                    editEnable: !selectAllNew,
                                                    isCheckBox: true))
        }
        rows.append(FeedMsgDisplayCellViewModel(userResolver: userResolver, type: .showNone, isSelected: selectNone))
        return rows
    }

    private func createRowsByOpt(_ selectedTypes: [FeedMsgDisplayItemType]) -> [FeedMsgDisplayCellItem] {
        var rows: [FeedMsgDisplayCellItem] = []
        let selectAll = selectedTypes.contains(.showAll)
        let selectNone = selectedTypes.contains(.showNone)
        let selectAllNew = selectedTypes.contains(.showAllNew)
        let selectNew = !selectAll && !selectNone && !selectAllNew
        rows.append(FeedMsgDisplayCellViewModel(userResolver: userResolver, type: .showAll, isSelected: selectAll))
        rows.append(FeedMsgDisplayCellViewModel(userResolver: userResolver, type: .showAllNew, isSelected: selectAllNew))
        rows.append(FeedMsgDisplayCellViewModel(userResolver: userResolver, type: .showNew, isSelected: selectNew))
        if selectNew {
            rows.append(FeedMsgDisplayCellViewModel(userResolver: userResolver, type: .showAtMeMentions,
                                                    isSelected: selectedTypes.contains(.showAtMeMentions),
                                                    editEnable: true,
                                                    isCheckBox: true))
            rows.append(FeedMsgDisplayCellViewModel(userResolver: userResolver, type: .showAtAllMentions,
                                                    isSelected: selectedTypes.contains(.showAtAllMentions),
                                                    editEnable: true,
                                                    isCheckBox: true))
            rows.append(FeedMsgDisplayCellViewModel(userResolver: userResolver, type: .showStarredContacts,
                                                    isSelected: selectedTypes.contains(.showStarredContacts),
                                                    editEnable: true,
                                                    isCheckBox: true))
        }
        rows.append(FeedMsgDisplayCellViewModel(userResolver: userResolver, type: .showNone, isSelected: selectNone))
        return rows
    }

    private func reload(_ rows: [FeedMsgDisplayCellItem]) {
        var headerTitle = ""
        var headerHeight: CGFloat = 0
        if !dependency.filterName.isEmpty {
            headerTitle = BundleI18n.LarkFeed.Lark_IM_MessageDisplaySettings_Desc(dependency.filterName)
            headerHeight = Cons.headerHeight
        }
        sections = [FeedMsgDisplaySectionVM(
            headerIdentifier: HeaderViewWithTitle.identifier,
            headerHeight: headerHeight,
            headerTitle: headerTitle,
            section: 0, rows: rows)]
        reloadDataSubject.onNext(())
    }

    private func syncFilterItemData(_ selectedTypes: [FeedMsgDisplayItemType], _ filterType: Feed_V1_FeedFilter.TypeEnum) {
        dependency.updateMsgDisplayFilterItem(FeedMsgDisplayFilterModel(userResolver: userResolver, selectedTypes: selectedTypes, filterType: filterType))
    }

    // MARK: - Public
    func getNavTitle() -> String {
        return BundleI18n.LarkFeed.Lark_FeedFilter_MessageDisplaySettings_ForTeamsAndLabelsOnly_Button
    }

    func updateOptions(_ selectedType: FeedMsgDisplayItemType) {
        if Feed.Feature(userResolver).groupSettingOptEnable {
            updateOptionsByOpt(selectedType)
        } else {
            updateOptionsByDefault(selectedType)
        }
    }

    private func updateOptionsByDefault(_ selectedType: FeedMsgDisplayItemType) {
        let filterItem = dependency.accessMsgDisplayFilterItem()
        var selectedTypes = filterItem.selectedTypes
        switch selectedType {
        case .showAll, .showNone:
            selectedTypes = [selectedType]
        case .showNew:
            selectedTypes = showNewSelectedTypes
        case .showAllNew:
            if selectedTypes.contains(selectedType) {
                selectedTypes = selectedTypes.filter({ $0 != selectedType })
            } else {
                selectedTypes = showNewSelectedTypes
            }
        case .showAtMeMentions, .showAtAllMentions, .showStarredContacts:
            if selectedTypes.contains(.showAllNew) { return }
            if selectedTypes.contains(selectedType) {
                // 删操作(至少要保留一个子选项)
                let atLeastExistTypes: [FeedMsgDisplayItemType] = [.showAtMeMentions, .showAtAllMentions, .showStarredContacts].filter({ $0 != selectedType })
                var canRemove = false
                for type in atLeastExistTypes {
                    if selectedTypes.contains(type) {
                        canRemove = true
                        break
                    }
                }
                if !canRemove {
                    hudShowRelay.accept(BundleI18n.LarkFeed.Lark_FeedFilter_SelectAtLeastOneTypeNewMessages_Toast)
                    return
                }
                selectedTypes = selectedTypes.filter({ $0 != selectedType })
            } else {
                // 增操作
                selectedTypes.append(selectedType)
            }
        }

        let rows = createRows(selectedTypes)
        syncFilterItemData(selectedTypes, filterItem.filterType)
        reload(rows)
    }

    private func updateOptionsByOpt(_ selectedType: FeedMsgDisplayItemType) {
        let filterItem = dependency.accessMsgDisplayFilterItem()
        var selectedTypes = filterItem.selectedTypes
        switch selectedType {
        case .showAll, .showNone, .showAllNew:
            selectedTypes = [selectedType]
        case .showNew:
            selectedTypes = showNewSelectedTypesByOpt
        case .showAtMeMentions, .showAtAllMentions, .showStarredContacts:
            if selectedTypes.contains(selectedType) {
                // 删操作(至少要保留一个子选项)
                let atLeastExistTypes: [FeedMsgDisplayItemType] = [.showAtMeMentions, .showAtAllMentions, .showStarredContacts].filter({ $0 != selectedType })
                var canRemove = false
                for type in atLeastExistTypes {
                    if selectedTypes.contains(type) {
                        canRemove = true
                        break
                    }
                }
                if !canRemove {
                    hudShowRelay.accept(BundleI18n.LarkFeed.Lark_FeedFilter_SelectAtLeastOneTypeNewMessages_Toast)
                    return
                }
                selectedTypes = selectedTypes.filter({ $0 != selectedType })
            } else {
                // 增操作
                selectedTypes.append(selectedType)
            }
        }

        let rows = createRowsByOpt(selectedTypes)
        syncFilterItemData(selectedTypes, filterItem.filterType)
        reload(rows)
    }

    func saveOptions() {
        dependency.saveMsgDisplayFilterItem()
    }

    enum Cons {
        static let headerHeight: CGFloat = 28.0
    }
}
