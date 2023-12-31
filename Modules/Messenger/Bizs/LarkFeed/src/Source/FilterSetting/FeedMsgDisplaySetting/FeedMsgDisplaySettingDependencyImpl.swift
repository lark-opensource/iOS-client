//
//  FeedMsgDisplaySettingDependencyImpl.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/22.
//

import Foundation
import RustPB
import RxSwift
import LarkContainer

final class FeedMsgDisplaySettingDependencyImpl: FeedMsgDisplaySettingDependency {
    let userResolver: UserResolver
    private var currentItem: FeedMsgDisplayFilterItem
    private let selectObservable: PublishSubject<FeedMsgDisplayFilterItem>
    private let _filterName: String
    init(userResolver: UserResolver,
         filterName: String,
         currentItem: FeedMsgDisplayFilterItem,
         selectObservable: PublishSubject<FeedMsgDisplayFilterItem>) {
        self.userResolver = userResolver
        self._filterName = filterName
        self.currentItem = currentItem
        self.selectObservable = selectObservable
    }

    var filterName: String {
        return _filterName
    }

    func accessMsgDisplayFilterItem() -> FeedMsgDisplayFilterItem {
        return currentItem
    }

    func updateMsgDisplayFilterItem(_ item: FeedMsgDisplayFilterItem) {
        let newItem = FeedMsgDisplayFilterModel(userResolver: userResolver,
            selectedTypes: item.selectedTypes,
            filterType: item.filterType,
            itemId: currentItem.itemId,
            itemTitle: currentItem.itemTitle)
        currentItem = newItem
    }

    func saveMsgDisplayFilterItem() {
        selectObservable.onNext(currentItem)
    }
}
