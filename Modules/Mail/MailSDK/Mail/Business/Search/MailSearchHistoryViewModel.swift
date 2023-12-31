//
//  SearchHistoryDataCenter.swift
//  Action
//
//  Created by tefeng liu on 2019/7/30.
//

import Foundation
import RxSwift
import RxRelay
import RustPB

protocol MailSearchHistoryViewModel {
    // property
    var state: BehaviorRelay<[MailSearchHistoryInfo]> { get }

    // action
    func save(info: MailSearchHistoryInfo)
    func deleteAllInfos()
    func getSearchHistory()
}

class MailSearchHistoryDataCenter: MailSearchHistoryViewModel {
    struct HistoryItem: MailSearchHistoryInfo {
        let keyword: String
    }

    // MARK: viewModel interface
    let state: BehaviorRelay<[MailSearchHistoryInfo]> = BehaviorRelay(value: [])

    // MARK: propery
    private let disposeBag = DisposeBag()

    func save(info: MailSearchHistoryInfo) {
        Store
            .fetcher?
            .saveSearchKeyWord(keyword: info.keyword)
            .subscribe(onNext: { (response) in
            // do something?
        }, onCompleted: { [weak self] in
            self?.getSearchHistory()
        }).disposed(by: disposeBag)
    }

    func deleteAllInfos() {
        state.accept([]) // 通知清空
        _ = Store.fetcher?.deleteAllSearchHistory().subscribe()
    }

    func getSearchHistory() {
        Store
            .fetcher?
            .getSearchHistory().subscribe(onNext: { [weak self] (response) in
            let result = response.keywords.map({ (keyword) -> HistoryItem in
                return HistoryItem(keyword: keyword)
            })
            self?.state.accept(result)
        }, onCompleted: {
            // done
        }).disposed(by: disposeBag)
    }
}
