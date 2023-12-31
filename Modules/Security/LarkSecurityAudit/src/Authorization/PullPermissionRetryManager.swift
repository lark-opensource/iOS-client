//
//  PullPermissionRetryManager.swift
//  LarkSecurityAudit
//
//  Created by ByteDance on 2022/11/17.
//

import Foundation
import LKCommonsLogging
import ServerPB
import ThreadSafeDataStructure
import LarkSecurityComplianceInfra
import LarkContainer
import LarkAccountInterface

final class PermissionRetryManager {
    private var currentRetryTask: PermissionRetryTask?
    static let logger = Logger.log(PermissionRetryManager.self, category: "SecurityAudit.PermissionRetryManager")

    let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func retryPullPermission(permVesion: String?, successBlock: @escaping(ServerPB_Authorization_PullPermissionResponse) -> Void) {
        clearRetryTask()
        currentRetryTask = PermissionRetryTask(resolver: resolver)
        currentRetryTask?.retryPullPermission(permVesion: permVesion, successBlock: successBlock)
    }

    func clearRetryTask() {
        currentRetryTask = nil
    }
}

final class PermissionRetryTask: UserResolverWrapper {
    var retryTimes: Int
    let delayTime: Int
    private var settings: AuditPermissionSetting
    private let fetcher: PermissionFetcher
    static let logger = Logger.log(PermissionRetryTask.self, category: "SecurityAudit.PermissionRetryTask")

    let userResolver: UserResolver

    init(resolver: UserResolver) {
        self.userResolver = resolver
        fetcher = PermissionFetcher(resolver: resolver)
        self.settings = AuditPermissionSetting.optPullPermissionsettings(userResolver: userResolver)
        self.retryTimes = self.settings.authzRetryCount
        self.delayTime = self.settings.authzRetryDelay
        Self.logger.info("pull_permission_opt:delayTime:\(self.settings.authzRetryDelay) retryCount\(self.settings.authzRetryCount)")
    }

    func retryPullPermission(permVesion: String?, successBlock: @escaping(ServerPB_Authorization_PullPermissionResponse) -> Void) {
        guard retryTimes > 0 else {
            return
        }
        retryTimes -= 1
        self.trackPullPermission(trigger: "retry", triggerSuccess: true)
        PullPermissionService.serialQueue.asyncAfter(deadline: .now() + .milliseconds(self.delayTime)) {
            self.fetcher.fetchPermissions(permVersion: permVesion, complete: { [weak self] (result) in
                guard let self = self else { return }
                let retrycount = self.settings.authzRetryCount - self.retryTimes
                let additionalData: [String: String] = ["trigger": "retry", "retry_time": "\(retrycount)"]
                switch result {
                case .success(let resp):
                    PullPermissionService.serialQueue.async {
                        successBlock(resp)
                    }
                    Self.logger.info("n_action_permission_fetch_req_retry_succ", additionalData: additionalData)
                case .failure(let error):
                    Self.logger.error("n_action_permission_fetch_req_retry_fail", additionalData: additionalData, error: error)
                    PullPermissionService.serialQueue.async {
                        self.retryPullPermission(permVesion: permVesion, successBlock: successBlock)
                    }
                }
            })
        }
    }

    private func trackPullPermission(trigger: String, triggerSuccess: Bool = true, triggerFailReason: String = "") {
        let service = try? userResolver.resolve(assert: PassportUserService.self)
        let tenantId = service?.user.tenant.tenantID ?? ""
        Events.track("scs_authz_pull_permission", params: ["trigger": trigger, "trigger_success": triggerSuccess ? 1 : 0, "trigger_fail_reason": triggerFailReason, "tenant_id": tenantId])
    }
}
