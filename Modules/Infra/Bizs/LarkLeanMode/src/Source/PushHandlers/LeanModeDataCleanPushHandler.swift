//
//  LeanModeDataCleanPushHandler.swift
//  LarkLeanMode
//
//  Created by 袁平 on 2020/3/16.
//

import Foundation
import RustPB
import LarkRustClient

final class LeanModeDataCleanPushHandler: UserPushHandler {

    private var leanModeAPI: LeanModeAPI? { try? userResolver.resolve(assert: LeanModeAPI.self) }

    func process(push message: PushCleanDataResponse) throws {
        leanModeAPI?.updateDataCleanObservable(message: message)
    }
}
