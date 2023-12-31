//
//  LeanModeLaunchTask.swift
//  LarkLeanMode
//
//  Created by KT on 2020/7/8.
//

import Foundation
import BootManager
import LarkContainer

final class LeanModeLaunchTask: UserFlowBootTask, Identifiable {
    static var identify = "LeanModeLaunchTask"

    override func execute(_ context: BootContext) {
        let leanModeService = try? self.userResolver.resolve(assert: LeanModeService.self)
        leanModeService?.fetchLeanModeStatusAndAuthority()
    }
}
