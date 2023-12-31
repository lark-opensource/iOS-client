//
//  FeedMsgDisplayMoreSettingDependencyImpl.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/29.
//

import Foundation
import RustPB
import RxSwift
import LarkContainer

final class FeedMsgDisplayMoreSettingDependencyImpl: FeedMsgDisplayMoreSettingDependency {
    var userResolver: UserResolver { labelViewModel.userResolver }
    private let labelViewModel: LabelMainListViewModel
    private let selectObservable: PublishSubject<[Int64: FeedMsgDisplayFilterItem]>
    private var tempUpdateRulesMap: [Int64: FeedMsgDisplayFilterItem] = [:]

    init(labelViewModel: LabelMainListViewModel,
         currentSelectedItemsMap: [Int64: FeedMsgDisplayFilterItem]?,
         selectObservable: PublishSubject<[Int64: FeedMsgDisplayFilterItem]>) {
        self.labelViewModel = labelViewModel
        self.selectObservable = selectObservable
        if let itemsMap = currentSelectedItemsMap {
            tempUpdateRulesMap = itemsMap
        }
    }

    func getLabelRules() -> [FeedMsgDisplayFilterItem] {
        let displayRules = labelViewModel.dataModule.store.getLabels().map({
            var types: [FeedMsgDisplayItemType]
            if let item = self.tempUpdateRulesMap[Int64($0.item.id)] {
                types = item.selectedTypes
            } else {
                types = FiltersModel.transformToSelectedTypes(userResolver: userResolver, $0.meta.extraData.displayRule)
            }
            return FeedMsgDisplayFilterModel(userResolver: userResolver,
                                             selectedTypes: types,
                                             filterType: .tag,
                                             itemId: Int64($0.item.id),
                                             itemTitle: $0.meta.feedGroup.name)
        })
        return displayRules
    }

    func updateLabelRuleItem(_ item: FeedMsgDisplayFilterItem) {
        guard let labelId = item.itemId else { return }
        tempUpdateRulesMap[labelId] = item
    }

    func saveChangedLabelRuleItems() {
        selectObservable.onNext(tempUpdateRulesMap)
    }
}
