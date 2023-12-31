//
//  EnvDelegate.swift
//  LarkAppConfig
//
//  Created by Yiming Qu on 2021/1/25.
//

import Foundation
import LarkEnv
import LKCommonsLogging

final class LarkAppConfigEnvDelegate: EnvDelegate {

    static let logger = Logger.log(LarkAppConfigEnvDelegate.self, category: "LarkAppConfig.EnvDelegate")
    var name: String = "LarkAppConfig"

    func config() -> EnvDelegateConfig {
        return [
            .after: .lowest
        ]
    }

    func envDidSwitch(_ result: EnvDelegateResult) {
        switch result {
        case .success(let (env, _)):
            Self.logger.info("send env change signal", additionalData: ["env": String(describing: env)])
            ConfigurationManager.shared._envSubjectV2.accept(env)
        case .failure(let error):
            Self.logger.error("switch env fail", error: error)
        }
    }
}
