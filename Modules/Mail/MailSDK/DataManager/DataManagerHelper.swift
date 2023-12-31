//
//  DataManagerHelper.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/11/20.
//

import Foundation
import RxSwift
import RxRelay

// MARK: Event Bus Property
@propertyWrapper
struct EventBusValue<Value> {
    private var _wrappedValue: PublishRelay<Value>
    var wrappedValue: Observable<Value> {
        get {
            return _wrappedValue.asObservable()
        }
    }

    // 通过$符号可以访问到
    @inlinable var projectedValue: EventBusValue {
        return self
    }

    init() {
        _wrappedValue = PublishRelay<Value>()
    }

    func accept(_ value: Value) {
        _wrappedValue.accept(value)
    }
}

// MARK: PushDispatcher property
@propertyWrapper
struct PushValue<Value> {
    private var _wrappedValue: PublishRelay<Value>
    var wrappedValue: Observable<Value> {
        get {
            return _wrappedValue.asObservable()
        }
    }

    // 通过$符号可以访问到
    @inlinable var projectedValue: PushValue {
        return self
    }

    init() {
        _wrappedValue = PublishRelay<Value>()
    }

    func accept(_ value: Value) {
        _wrappedValue.accept(value)
    }
}


// MARK: DataManager Property
@propertyWrapper
struct DataManagerValue<Value> {
    private var _wrappedValue: PublishRelay<Value>
    var wrappedValue: Observable<Value> {
        get {
            return _wrappedValue.asObservable()
        }
    }

    // 通过$符号可以访问到
    @inlinable var projectedValue: DataManagerValue {
        return self
    }

    init() {
        _wrappedValue = PublishRelay<Value>()
    }

    func accept(_ value: Value) {
        _wrappedValue.accept(value)
    }
}

extension DataManagerValue: ObserverType {
    func on(_ event: Event<Value>) {
        switch event {
        case .next(let value):
            _wrappedValue.accept(value)
        default:
            assert(false, "you can not receive Complete Or Error!")
        }
    }
}
