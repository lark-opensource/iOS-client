//
//  ObservableExtensions.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/10/9.
//

import Foundation
import RxSwift
import RxCocoa

extension ObservableType {

    func filterFlatMap<U>(transform: @escaping (Element) -> U?) -> Observable<U> {
        return self.flatMap { element -> Observable<U> in
            if let transformed = transform(element) {
                return .just(transformed)
            } else {
                return .empty()
            }
        }
    }

    func filterByLatestFrom(_ predicate: Observable<Bool>) -> Observable<Element> {
        return withLatestFrom(predicate) { ($0, $1) }
            .filter { return $0.1 }
            .map { return $0.0 }
    }

    func filterByCombiningLatest(_ predicate: Observable<Bool>) -> Observable<Element> {
        return Observable.combineLatest(self, predicate) { ($0, $1) }
            .filter { return $0.1 }
            .map { return $0.0 }
    }
}

extension ObservableType where Element: Equatable {

    func takeUntil(_ value: Element) -> Observable<Element> {
        var flag = false
        return self.flatMap { element -> Observable<Element> in
            if element == value { flag = true }
            if flag {
                return .just(element)
            } else {
                return .empty()
            }
        }
    }
}
