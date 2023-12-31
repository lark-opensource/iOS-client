//
//  LarkMagicLaunchTask.swift
//  LarkMagic
//
//  Created by mochangxing on 2020/10/19.
//

import Foundation
import BootManager
import LarkContainer
import ADFeelGood
import LarkAccountInterface
import LKCommonsTracker
import LarkReleaseConfig
import LarkLocalizations
import RxSwift
import LarkRustClient
import LarkFeatureGating
import LKCommonsLogging
import LarkUIKit
import LarkPrivacySetting

final class LarkMagicLaunchTask: UserFlowBootTask, Identifiable {
    static var identify = "LarkMagicLaunchTask"
    @ScopedProvider private var deviceService: DeviceService?
    @ScopedProvider private var configurationAPI: LarkMagicConfigAPI?
    @ScopedProvider private var larkMagicService: LarkMagicService?
    private let disposeBag = DisposeBag()
    static let logger = Logger.log(LarkMagicLaunchTask.self, category: "LarkMagic")

    private var setupTask: LarkMagicSDKSetupTask?

    deinit {
        LarkMagicLaunchTask.logger.info("LarkMagicLaunchTask deinit")
    }

    override func execute(_ context: BootContext) {
        let enabled = userResolver.fg.staticFeatureGatingValue(with: "lark.magic.enable")
        let setupTask = LarkMagicSDKSetupTask(resolver: userResolver)
        self.setupTask = setupTask
        let service = self.larkMagicService as? LarkMagicServiceImpl
        service?.setupTask = self.setupTask
        Self.logger.info("LarkMagicLaunchTask excute: \(enabled), \(String(describing: service)), \(setupTask)")
        guard enabled else {
            return
        }
        // 私有化场景不支持Feelgood
        if ReleaseConfig.isKA && ReleaseConfig.kaDeployMode != .saas {
            Self.logger.info("LarkMagicLaunchTask excute is not saas")
            return
        }
        setupTask.fetchConfig()
    }
}
