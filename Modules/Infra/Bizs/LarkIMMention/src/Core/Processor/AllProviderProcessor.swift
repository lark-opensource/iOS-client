//
//  AllProviderProcessor.swift
//  LarkIMMention
//
//  Created by Yuri on 2022/12/14.
//

import Foundation
import RxSwift

enum SignalType {
    case chatter
    case doc
}

class AllProviderProcessor {
    static func reduce(query: String?, events: [ProviderEvent]) -> ProviderEvent {
        let results = events.reduce([IMMentionOptionType]()) {
            if case .success(let res) = $1 {
                let res = $0 + res.res.result.flatMap { $0 }
                return res
            }
            return $0
        }
        if results.isEmpty {
            for event in events {
                guard case .fail(let providerError) = event else {
                    continue
                }
                // 请求错误时, 直接返回该错误
                if case .request(_) = providerError {
                    return event
                }
            }
            if let query = query, !query.isEmpty {
                return ProviderEvent.fail(.noSearchResult)
            } else {
                return ProviderEvent.fail(.noRecommendResult)
            }
        } else {
            let result = ProviderResult(result: [results], hasMore: false)
            return ProviderEvent.success(.init(query: query, res: result))
        }
    }
    
    var items = [IMMentionOptionType]()
    let disposeBag = DisposeBag()
    
    var isDispatchedFailed: Bool = false
    var isDispatchedLoading: Bool = false
    func startSearch() {
        isDispatchedFailed = false
        isDispatchedLoading = false
        items = [IMMentionOptionType]()
    }
    
//    func createAllObservable(obs: [Observable<(ProviderEvent, SignalType)>]) -> Observable<ProviderEvent> {
//        return Observable.create { ob in
//            Observable.merge(obs)
//                .subscribe { (event, type) in
//                    switch event {
//                    case .fail(let err):
//                        ob.onNext(event)
//                        ob.onCompleted()
//                        self.isDispatchedFailed = true
//                    case .loading(let query):
//                        ob.onNext(event)
//                        self.isDispatchedLoading = true
//                    case .success():
//                        switch type {
//                        case .chatter: ob.onNext(<#T##element: ProviderEvent##ProviderEvent#>)
//                    }
//                }.disposed(by: self.disposeBag)
//            return Disposables.create()
//        }
//    }
    
    func processChatter(event: ProviderEvent) -> ProviderEvent? {
        
        return nil
    }
    func processDocument(event: ProviderEvent) -> ProviderEvent? {
        return nil
    }
    func processRecommendChatter(event: ProviderEvent) -> [IMMentionOptionType] {
        return items
    }
    func processSearchChatter(event: ProviderEvent) -> [IMMentionOptionType] {
        return items
    }
    func processRecommendDocument(event: ProviderEvent) -> [IMMentionOptionType] {
        return items
    }
    func processSearchDocument(event: ProviderEvent) -> [IMMentionOptionType] {
        return items
    }
}
