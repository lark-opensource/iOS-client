//
//  SecurityStateDependencyImpl.swift
//  ByteViewMod
//
//  Created by bytedance on 2022/5/25.
//

import Foundation
import LarkSecurityComplianceInterface
import ByteView
import ByteViewCommon
import LarkEMM
import LarkSensitivityControl
import LarkContainer

final class SecurityStateDependencyImpl: SecurityStateDependency {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func didSecurityViewAppear() -> Bool {
        if let sCService = try? userResolver.resolve(assert: SecurityComplianceService.self) {
            return sCService.state != .idle
        }
        return false
    }

    func vcScreenCastChange(_ vcCast: Bool) {
        if let screenProtectionService = try? userResolver.resolve(assert: ScreenProtectionService.self) {
            screenProtectionService.vcScreenCastChange(vcCast)
        }
    }

    func setPasteboardText(_ message: String, token: String, shouldImmunity: Bool) -> Bool {
        do {
            // shouldImmunity表示是否豁免该次复制
            let config = PasteboardConfig(token: Token(token), shouldImmunity: shouldImmunity)
            try SCPasteboard.generalUnsafe(config).string = message
            return true
        } catch {
            Logger.privacy.warn("Cannot copy string: token \(token) is disabled, \(error)")
            return false
        }
    }

    func getPasteboardText(token: String) -> String? {
        let config = PasteboardConfig(token: Token(token))
        return SCPasteboard.general(config).string
    }
}
