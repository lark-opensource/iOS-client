//
//  AppLogEnvDelegate.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/25.
//

import Foundation
import LarkEnv
import LarkContainer
import LKCommonsLogging

class AppLogEnvDelegate: EnvDelegate {

    static let logger = Logger.plog(AppLogEnvDelegate.self, category: "SuiteLogin.AppLogEnvDelegate")

    var name: String = "AppLog"

    func config() -> EnvDelegateConfig {
        return [
            .after: .low
        ]
    }

    func envDidSwitch(_ result: EnvDelegateResult) {
        switch result {
        case .success(let (env, _)):
            afterSwitchEnv(env)
        case .failure(let error):
            Self.logger.error("switch env fail", error: error)
        }
    }

    func afterSwitchEnv(_ env: Env) {
        Self.logger.info("switch env", additionalData: [
            "env": String(describing: env),
            "host": String(describing: PassportConf.shared.serverInfoProvider.getUrl(.api))
        ], method: .local)

        AccountIntegrator.shared.updateAppLog()
    }
}
