//
//  RustMigrateAPI.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/10.
//

import Foundation
import RxSwift
import LarkRustClient
import LarkContainer
import RustPB

typealias MigrateResetRequest = RustPB.Passport_V1_ResetRequest

class RustMigrateAPI: MigrateAPI {

    @Provider var client: GlobalRustService
    
    func migrateReset() -> Observable<Void> {
        let request = MigrateResetRequest()
        return client.sendAsyncRequest(request)
    }
}
