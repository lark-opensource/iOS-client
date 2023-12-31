//
//  SearchQueryVM.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/6/9.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkSDKInterface
import LarkSearchFilter

/// 代表抽象的查询视图状态
public final class SearchQueryVM {
    /// use input text
    public let text = BehaviorRelay(value: "")
    /// use choose filters
    public let filters = BehaviorRelay<[SearchFilter]>(value: [])
    /// additional params pass to the source
    public let context = BehaviorRelay<SearchRequestContext>(value: .init())
}
