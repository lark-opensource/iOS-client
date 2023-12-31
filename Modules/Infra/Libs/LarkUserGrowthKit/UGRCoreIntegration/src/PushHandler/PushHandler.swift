//
//  PushHandler.swift
//  UGRCoreIntegration
//
//  Created by shizhengyu on 2021/3/24.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient
import LarkContainer

final class PushScenarioInfoHandler: UserPushHandler {
    @ScopedInjectedLazy private var coreDispatchService: ReachCoreService?

    func process(push message: PushUGScenarioInfo) throws {
        let reachPointIds = message.reachPointIds.reachPointIds
        if reachPointIds.isEmpty || !message.hasScenarioID {
            return
        }
        coreDispatchService?.tryExpose(
            by: message.scenarioID,
            specifiedReachPointIds: reachPointIds
        )
    }
}
