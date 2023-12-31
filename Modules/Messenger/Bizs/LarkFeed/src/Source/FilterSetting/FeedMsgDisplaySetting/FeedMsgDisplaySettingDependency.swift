//
//  FeedMsgDisplaySettingDependency.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/22.
//

import Foundation
import RustPB
import LarkContainer

protocol FeedMsgDisplaySettingDependency: UserResolverWrapper {
    var filterName: String { get }
    func accessMsgDisplayFilterItem() -> FeedMsgDisplayFilterItem
    func updateMsgDisplayFilterItem(_ item: FeedMsgDisplayFilterItem)
    func saveMsgDisplayFilterItem()
}

extension FeedMsgDisplaySettingDependency {
    var filterName: String { return "" }
    func accessMsgDisplayFilterItem() -> FeedMsgDisplayFilterItem {
        return FeedMsgDisplayFilterModel(userResolver: userResolver, selectedTypes: [], filterType: .unknown)
    }
    func updateMsgDisplayFilterItem(_ item: FeedMsgDisplayFilterItem) {}
    func saveMsgDisplayFilterItem() {}
}
