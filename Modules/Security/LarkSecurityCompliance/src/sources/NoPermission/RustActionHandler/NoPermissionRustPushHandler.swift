//
//  NoPermissionRustPushHandler.swift
//  LarkSecurityAndCompliance
//
//  Created by qingchun on 2022/4/7.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSecurityComplianceInfra

typealias PushReqRegulateResponse = Basic_V1_PushReqRegulateResponse

final class NoPermissionRustPushHandler: UserPushHandler { // Global

    typealias PushType = PushReqRegulateResponse

    override class var compatibleMode: Bool { SCContainerSettings.userScopeCompatibleMode }

    let decision: NoPermissionRustActionDecision
    @ScopedProvider private var service: NoPermissionService?

    override init(resolver: UserResolver) {
        self.decision = NoPermissionRustActionDecisionImp(resolver: resolver)
        super.init(resolver: resolver)
        Logger.info("init NoPermissionRustPushHandler")
    }

    func process(push: PushReqRegulateResponse) throws {
        DispatchQueue.main.async {
            do {
                let isNoPermission = (self.service?.isInNoPermision).isTrue
                guard !isNoPermission else { return }
                let model = try NoPermissionRustActionModel(push)
                SecurityPolicyEventTrack.larkSCSHandleAction(actionSource: .responseHeader,
                                                             actionName: model.model?.name ?? "NO_ACTION")
                self.decision.handleAction(model)
                SCMonitor.info(business: .no_permission, eventName: "receive_rust_push_message", category: ["logId": model.logId])
                Logger.info("handle action: \(push)")
            } catch {
                SCMonitor.error(business: .no_permission, eventName: "receive_rust_push_message", error: error, extra: ["logId": push.xTtLogid])
                Logger.error(error.localizedDescription)
            }
        }
    }
}
