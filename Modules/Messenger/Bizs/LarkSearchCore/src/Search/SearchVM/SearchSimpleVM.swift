//
//  SearchSimpleVM.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/6/9.
//

import Foundation
import RxSwift

/// 负责单一数据源的简单Search页面场景的相关Search逻辑
public final class SearchSimpleVM<Item> {
    public let query = SearchQueryVM()
    public var result: SearchListVM<Item>
    public var bag = DisposeBag()
    public var filterBottomPadding: Int = Picker.UI.defaultBottomPadding

    public init(result: SearchListVM<Item>) {
        self.result = result
        bind()
    }

    func bind() {
        query.bind(to: result).disposed(by: bag)
    }

    public func rebind(result: SearchListVM<Item>) {
        self.result = result
        self.bag = DisposeBag()
        query.bind(to: result).disposed(by: bag)
    }
}
