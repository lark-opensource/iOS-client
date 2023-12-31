//
//  RustShareDynamicAPI.swift
//  LarkSnsShare
//
//  Created by shizhengyu on 2020/11/21.
//

import Foundation
import RustPB
import LarkRustClient
import RxSwift

final class RustShareDynamicAPI: ShareDynamicAPI {
    let client: RustService
    let scheduler: ImmediateSchedulerType?

    init(client: RustService, scheduler: ImmediateSchedulerType? = nil) {
        self.client = client
        self.scheduler = scheduler
    }

    func fetchDynamicConfigurations(fields: [String]) -> Observable<[String: String]> {
        var request = RustPB.Settings_V1_GetSettingsRequest()
        request.fields = fields
        return client.sendAsyncRequest(request, transform: { (response: Settings_V1_GetSettingsResponse) -> [String: String] in
            return response.fieldGroups
        }).subscribeOn(scheduler)
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
