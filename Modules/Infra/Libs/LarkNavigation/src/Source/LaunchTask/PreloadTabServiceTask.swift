//
//  PreloadTabServiceTask.swift
//  LarkNavigation
//
//  Created by KT on 2020/7/13.
//

import Foundation
import BootManager
import LarkContainer
import LarkAccountInterface

final class PreloadTabServiceTask: UserFlowBootTask, Identifiable {
    static var identify = "PreloadTabServiceTask"

    override func execute(_ context: BootContext) {
        NewBootManager.shared.addConcurrentTask {
            _ = try? self.userResolver.resolve(assert: NavigationConfigService.self)
        }
        NewBootManager.shared.addConcurrentTask {
            _ = try? self.userResolver.resolve(assert: SwitchAccountService.self)
        }
    }
}
