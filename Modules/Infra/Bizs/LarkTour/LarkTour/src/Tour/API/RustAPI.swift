//
//  RustAPI.swift
//  LarkTour
//
//  Created by Meng on 2020/6/7.
//

import Foundation
import LarkRustClient
import LarkModel
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
