//
//  PrivacyAlertLaunchTask.swift
//  LarkPrivacyAlert
//
//  Created by KT on 2020/6/30.
//

import Foundation
import AppContainer
import LarkAppConfig
import BootManager
import LarkPrivacyMonitor

public final class PrivacyCheckTask: BranchBootTask, Identifiable {
    public static var identify = "PrivacyCheckTask"

    public override var runOnlyOnceInUserScope: Bool { return false }

    public override func execute(_ context: BootContext) {
        if !PrivacyAlertManager.shared.hasSignedPrivacy() {
            NewBootManager.shared.context.blockDispatcher = true
            self.flowCheckout(.privacyAlertFlow)
        }
        // Monitor SDK 隐私弹窗逻辑注入
        PrivacyMonitor.shared.configPrivacy(with: PrivacyAlertManager.shared)
    }
}

public final class PrivacyBizTask: AsyncBootTask, Identifiable {
    public static var identify = "PrivacyBizTask"

    public override var runOnlyOnceInUserScope: Bool { return false }

    public override func execute(_ context: BootContext) {
        let alertVC = PrivacyAlertManager.shared.privacyAlertController { [weak self] in
            PrivacyMonitor.shared.uploadEventCacheAfterHasAgreedPrivacy()
            self?.end()
            NewBootManager.shared.context.blockDispatcher = false
        }
        context.window?.rootViewController = alertVC
    }
}
