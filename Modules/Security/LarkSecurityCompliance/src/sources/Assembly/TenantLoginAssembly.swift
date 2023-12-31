//
//  TenantLoginAssembly.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/2/2.
//

import Foundation
import LarkContainer
import BootManager
import LarkAssembler
import LarkSecurityComplianceInfra
import LarkSetting

final class TenantLoginAssembly: LarkAssemblyInterface {
    func registContainer(container: Container) {
        let userContainer = container.inObjectScope(SCContainerSettings.userScope)
        userContainer.register(TenantLoginControlProtocol.self) { resolver in
            try TenantLoginControl(userResolver: resolver)
        }
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(TenantRestrictTask.self)
    }
}

final class TenantRestrictTask: UserFlowBootTask, Identifiable {

    static var identify = "TenantRestrictTask"
    override class var compatibleMode: Bool { SCContainerSettings.userScopeCompatibleMode }

    override func execute() throws {
        let tenantLoginControl = try userResolver.resolve(assert: TenantLoginControlProtocol.self)
        tenantLoginControl.start()
    }
}
