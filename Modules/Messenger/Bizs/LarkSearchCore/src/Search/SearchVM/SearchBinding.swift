//
//  SearchBinding.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/6/9.
//

import Foundation
import RxSwift
import RxCocoa
import LarkSearchFilter

// 该文件负责扩展提供一部分可被调用的默认binding行为

extension SearchQueryVM {
    public func bind<T>(to list: SearchListVM<T>) -> Disposable {
        return Observable.combineLatest(text, filters, context)
        .debounce(.milliseconds(Int(SearchRemoteSettings.shared.searchDebounce * 1000)), scheduler: MainScheduler.asyncInstance)
        .bind(onNext: list.search(query:filters:context:))
    }
}
