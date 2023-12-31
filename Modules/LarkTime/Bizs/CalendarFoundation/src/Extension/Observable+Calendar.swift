//
//  Observable+Calendar.swift
//  Calendar
//
//  Created by harry zou on 2019/4/12.
//

import Foundation
import RxSwift

extension ObservableType {
    public func subscribeForUI(onNext: ((Self.Element) -> Void)? = nil,
                               onError: ((Error) -> Void)? = nil,
                               onCompleted: (() -> Void)? = nil,
                               onDisposed: (() -> Void)? = nil) -> Disposable {
        return self.observeOn(MainScheduler.instance).subscribe(onNext: onNext, onError: onError, onCompleted: onCompleted, onDisposed: onDisposed)
    }
}
