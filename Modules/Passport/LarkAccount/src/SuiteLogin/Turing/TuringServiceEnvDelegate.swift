//
//  TuringServiceEnvDelegate.swift
//  LarkAccount
//
//  Created by Nix Wang on 2021/11/12.
//

import LKCommonsLogging
import LarkEnv

class TuringServiceEnvDelegate: EnvDelegate {
    static let logger = Logger.plog(TuringService.self, category: "SuiteLogin.TuringService")
    
    var name: String = "LarkAppConfig"
    
    func config() -> EnvDelegateConfig {
        return [
            .after: .low
        ]
    }
    
    func envDidSwitch(_ result: EnvDelegateResult) {
        switch result {
        case .success(let (env, _)):
            Self.logger.info("switch env succ", method: .local)
            TuringService.shared.updateConfig(env: env)
        case .failure(let error):
            Self.logger.error("switch env fail", error: error)
        }
    }
}
