//
//  ObservePasteboardTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/8.
//

import Foundation
import BootManager
import LarkAccountInterface
import LarkReleaseConfig
import LarkEnv
import LarkFeatureGating
import LarkContainer
import LarkSetting

final class ObservePasteboardTask: UserFlowBootTask, Identifiable {
    static var identify = "ObservePasteboardTask"

    override func execute() throws {
        ObservePasteboardLauncherDelegate.logger.info("afterAccountLoaded")
        // 海外版无分享口令
        guard ReleaseConfig.releaseChannel != "Oversea" else { return }
        // 国内动态环境是海外的也禁掉
        let user = try userResolver.resolve(assert: PassportUserService.self).user
        guard user.isChinaMainlandGeo else {
            ObservePasteboardLauncherDelegate.logger.info("internal dynamic environment is isOversea")
            return
        }
        let shareTokenEnable = try userResolver.resolve(assert: FeatureGatingService.self)
            .staticFeatureGatingValue(with: .init(stringLiteral: FeatureGatingKey.shareTokenEnable.rawValue))
        let delegate = userResolver.resolve(ObservePasteboardLauncherDelegate.self)! // Global
        if shareTokenEnable {
            delegate.addObserverToObservePasteboard()
        } else {
            delegate.removeObserverToObservePasteboard()
        }
    }
}
