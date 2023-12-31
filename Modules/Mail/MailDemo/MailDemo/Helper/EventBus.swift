//
//  EventBus.swift
//  MailDemo
//
//  Created by tefeng liu on 2021/12/22.
//

import Foundation
import RxSwift
import RxRelay
import LarkSDKInterface
import RustPB
import LarkMessengerInterface
import RxCocoa


extension DemoEventBus {
    enum RouterEvent {
        case namecard
    }
}

class DemoEventBus {
    static let shared = DemoEventBus()

    @EventValue<RouterEvent> var router

    func fireRouterEvent(event: RouterEvent) {
        $router.accept(event)
    }

    // MARK: ValueType
    @propertyWrapper
    struct EventValue<Value> {
        private var _wrappedValue: PublishSubject<Value>
        var wrappedValue: Observable<Value> {
            return _wrappedValue.asObservable()
        }

        // 通过$符号可以访问到
        @inlinable var projectedValue: EventValue {
            return self
        }

        init() {
            _wrappedValue = PublishSubject<Value>()
        }

        func accept(_ value: Value) {
            _wrappedValue.onNext(value)
        }
    }

}
