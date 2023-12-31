//
//  Observable+Condition.swift
//  Calendar
//
//  Created by Rico on 2021/5/14.
//

import Foundation
import RxSwift
import RxRelay

extension ObservableType {
    func when(_ relay: BehaviorRelay<Bool>) -> Observable<Self.Element> {
        return filter { _ in relay.value }
    }

    func whenNot(_ relay: BehaviorRelay<Bool>) -> Observable<Self.Element> {
        return filter { _ in !relay.value }
    }
}
