//
//  KeyBoardApplicationDelegate.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/10/25.
//

import Foundation
import AppContainer
import LarkContainer
import LarkSecurityComplianceInfra
import LarkAccountInterface

public final class KeyBoardApplicationDelegate: ApplicationDelegate {
    public static var config = Config(name: "KeyBoard", daemon: true)

    public required init(context: AppContainer.AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message) in
            return self?.allowExtension(message) ?? true
        }
    }

    private func allowExtension(_ message: AllowExtensionPoint) -> AllowExtensionPoint.HandleReturnType {
        // TODO: cqc 后续适配
        let passportService = BootLoader.container.resolve(PassportService.self)
        guard let userID = passportService?.foregroundUser?.userID else { return true } // Global
        let resolver = try? BootLoader.container.getUserResolver(userID: userID)
        let pasteService = try? resolver?.resolve(assert: PasteboardService.self)
        if message.identifier.rawValue == "com.apple.keyboard-service" {
            let checkProtectPermission = pasteService?.shouldDisableThirdKeyboard() ?? false
            let allowThirdKeyboardShow = !checkProtectPermission
            return allowThirdKeyboardShow
        }
        return true
    }
}
