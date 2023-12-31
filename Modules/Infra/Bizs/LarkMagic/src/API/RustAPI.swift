//
//  RustAPI.swift
//  LarkMagic
//
//  Created by mochangxing on 2020/11/3.
//

import Foundation
import LarkRustClient
import RxSwift

class RustAPI {
    let client: RustService
    let scheduler: ImmediateSchedulerType?

    init(client: RustService, scheduler: ImmediateSchedulerType? = nil) {
        self.client = client
        self.scheduler = scheduler
    }
}

extension ObservableType {
    func subscribeOn(_ scheduler: ImmediateSchedulerType? = nil) -> Observable<Self.Element> {
        if let scheduler = scheduler {
            return self.subscribeOn(scheduler)
        }
        return self.asObservable()
    }
}
