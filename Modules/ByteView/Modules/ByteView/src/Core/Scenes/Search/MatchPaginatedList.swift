//
//  MatchPaginatedList.swift
//  ByteView
//
//  Created by huangshun on 2019/6/4.
//

import Foundation
import RxSwift
import Action

class MatchPaginatedList<T> {

    enum MatchResult {
        case loading
        case results([T], Bool)
        case noMatch
    }

    let disposed = DisposeBag()
    var pagerDisposed = DisposeBag()

    // (搜索文字, 搜索区间) -> (数据, 是否存在更多数据)
    let loader: Action<(String?, Range<Int>), ([T], Bool)>

    private let trigger: PublishSubject<Void> = PublishSubject()
    private let input: PublishSubject<String?> = PublishSubject()
    private let output: PublishSubject<MatchResult> = PublishSubject()

    init(_ loader: Action<(String?, Range<Int>), ([T], Bool)>, step: Int = 30) {
        self.loader = loader

        input.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] text in
                self?.output.onNext(.loading)
                self?.setPager(text, step: step)
                self?.loadNext.onNext(())
            })
            .disposed(by: disposed)
    }

    func setPager(_ text: String?, step: Int) {
        var index = 0
        // 每次搜索文字改变订阅一个新的流
        pagerDisposed = DisposeBag()
        let loader = self.loader

        // 下一页监听者转换为数据接口、页码加一
        let pager = trigger.flatMapLatest { _ -> Observable<([T], Bool)> in
            let nsRange = NSRange(location: index * step, length: step)
            let range = Range<Int>(nsRange)!
            return loader.workFactory((text, range)).do(onNext: { _ in index += 1 })
            }
            .catchError { _ in .just(([], true)) } // ([], true) 代表加载失败

        // 合并上次查找的数据
        let data = pager.scan(([], true)) { (arg1, arg2) -> ([T], Bool) in
            let items = arg1.0 + arg2.0
            return (items, arg2.1)
            }

        data.subscribe(onNext: { [weak self] (items, hasMore) in
            self?.output.onNext(items.isEmpty ? .noMatch : .results(items, hasMore))
        }).disposed(by: pagerDisposed)
    }

    var loadNext: AnyObserver<Void> {
        return trigger.asObserver()
    }

    var text: AnyObserver<String?> {
        return input.asObserver()
    }

    var result: Observable<MatchResult> {
        return output.asObservable()
    }
}
