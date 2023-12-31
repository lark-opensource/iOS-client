//
//  LarkEMMAssembly.swift
//  LarkEMM
//
//  Created by ByteDance on 2022/7/20.
//

import Foundation
import LarkAssembler
import Swinject
import BootManager
import LarkContainer
import AppContainer
import LarkSecurityComplianceInfra

public final class LarkEMMAssembly: LarkAssemblyInterface {
        
    public init() {}
    
    private lazy var subAssemblies: [LarkAssemblyInterface] = {
        var assemblies = [LarkAssemblyInterface]()
        assemblies.append(AppLockAssembly())
        return assemblies
    }()

    public func registContainer(container: Container) {
        let userContainer = container.inObjectScope(SCContainerSettings.userScope)
        userContainer.register(ScreenProtectionService.self) { _ in
            ScreenProtectionServiceImp()
        }
        userContainer.register(PasteboardService.self) { resolver in
            try PasteboardServiceImp(resolver: resolver)
        }
        userContainer.register(EMMConfig.self) { resolver in
            try EMMConfigImp(resolver: resolver)
        }
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(LarkEMMSyncTask.self)
    }

    public func registBootLoader(container: Container) {
        (KeyBoardApplicationDelegate.self, DelegateLevel.default)
    }
    
    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        return subAssemblies
    }
}

final class LarkEMMSyncTask: UserFlowBootTask, Identifiable {
    static var identify = "LarkEMMSyncTask"
    override class var compatibleMode: Bool { SCContainerSettings.userScopeCompatibleMode }
    public override var forbiddenPreload: Bool { return true }
    override func execute() throws {
        let emmConfig = try userResolver.resolve(assert: EMMConfig.self)
        if emmConfig.isPasteProtectDisabled {
            return
        }
        SCPasteboard.startSDK(resolver: userResolver)
    }
}
