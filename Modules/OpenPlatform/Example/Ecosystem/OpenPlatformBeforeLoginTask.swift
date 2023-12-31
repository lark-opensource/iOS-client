//
//  OpenPlatformBeforeLoginTask.swift
//  LarkOpenPlatform
//
//  Created by ChenMengqi on 2022/2/8.
//

import Foundation
import BootManager
import LKLoadable
import TTMicroApp
import LarkMicroApp
import AppContainer
import WebBrowser
import LarkUIKit
import LarkContainer
import LarkSetting

final class OpenPlatformBeforeLoginTask: FlowBootTask, Identifiable {
    static var identify: TaskIdentify = "OpenPlatformBeforeLoginTask"
    override var runOnlyOnce: Bool {
        return true
    }

    override func execute(_ context: BootContext) {
        OpenAppEngine.shared.assembleSetup(resolver: BootLoader.container, larkOpenProtocolType: EMAProtocolImpl.self, larkLiveFaceDelegate: EMALiveFaceProtocolImpl())
        setupConfig()
    }

    private func setupConfig() {
        EMAConfigManager.setSettingsFetchServiceProviderWith({
            return Injected<ECOSettingsFetchingService>().wrappedValue
        })
        EMAConfigManager.registeLegacyKey()
    }
}
