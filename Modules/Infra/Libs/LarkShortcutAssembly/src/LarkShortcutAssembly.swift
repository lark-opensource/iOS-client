//
//  LarkShortcutAssembly.swift
//  LarkShortcutAssembly
//
//  Created by kiri on 2023/11/16.
//

import Foundation
import Swinject
import LarkAssembler
import LarkSetting
import LarkContainer
import LarkShortcut
import RxSwift

public final class LarkShortcutAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(.userV2)
        user.register(ShortcutService.self) { r in
            let settingService = try r.resolve(assert: SettingService.self)
            let config = (try? settingService.setting(with: ShortcutConfig.self, key: .shortcutConfig)) ?? .none
            let service = ShortcutService(userId: r.userID, config: config)
            _ = settingService.observe(type: ShortcutConfig.self, key: .shortcutConfig).subscribe(onNext: { [weak service] in
                service?.updateConfig($0)
            })
            return service
        }
    }
}

private extension UserSettingKey {
    static let shortcutConfig = UserSettingKey.make(userKeyLiteral: "shortcut_config")
}
