//
//  UpdateAuditTask.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/11/29.
//

import Foundation
import BootManager
import LarkContainer
import LarkAccountInterface
import LarkSetting

final class UpdateAuditTask: UserFlowBootTask, Identifiable {
    static var identify = "UpdateAuditTask"
    public override var forbiddenPreload: Bool { return true }
    static func getApiDomain() -> String {
        return "\(DomainSettingManager.shared.currentSetting[.api]?.first ?? "")"
    }

    @ScopedProvider var deviceService: DeviceService?
    @ScopedProvider var userService: PassportUserService?

    override func execute(_ context: BootContext) {
        let deviceId = deviceService?.deviceId ?? ""
        let session = userService?.user.sessionKey ?? ""
        let config = Config(
            hostProvider: {
                Self.getApiDomain()
            },
            deviceId: deviceId,
            session: session
        )
        SecurityAuditManager.shared.initSDK(config)
        SecurityAuditManager.shared.start(resolver: userResolver)
    }
}
