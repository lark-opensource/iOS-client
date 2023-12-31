//
//  PickerRecommendLoadable.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/6/6.
//

import Foundation
import RxSwift

public struct PickerRecommendResult {
    public var items: [PickerItem]
    public var hasMore: Bool = false
    /// 加载更多数据时, 是否是分页数据
    /// True: 分页数据, 每次加载固定个数的数据, 列表会自动累加
    /// False: 加载更多时直接返回全部数据, 列表会替换所有数据
    public var isPage: Bool = true
    public init(items: [PickerItem], hasMore: Bool, isPage: Bool) {
        self.items = items
        self.hasMore = hasMore
        self.isPage = isPage
    }
}

public protocol PickerRecommendLoadable {
    func load() -> Observable<PickerRecommendResult>
    func loadMore() -> Observable<PickerRecommendResult>
}
