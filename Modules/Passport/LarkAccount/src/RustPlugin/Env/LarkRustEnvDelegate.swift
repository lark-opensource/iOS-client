//
//  LarkRustEnvDelegate.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/25.
//

import Foundation
import LarkEnv
import RxSwift
import RustPB
import LarkContainer
import LarkRustClient
import LarkAppConfig
import LarkSetting
import LKCommonsLogging

typealias DomainSettings = RustPB.Basic_V1_DomainSettings
typealias SetEnvResponse = RustPB.Basic_V1_SetEnvResponse

// 登录前日志排查的问题，先放在LarkAccount的RustPlugin

class LarkRustEnvDelegate: EnvDelegate {

    static let logger = Logger.plog(LarkRustEnvDelegate.self, category: "RustPlugin.LarkRustEnvDelegate")

    @Provider var client: GlobalRustService

    var name: String = "LarkRustEnv"

    func config() -> EnvDelegateConfig {
        return [
            .before: .highest
        ]
    }

    func envWillSwitch(_ futureEnv: Env, payload: [AnyHashable: Any]) -> Observable<Void> {
        guard let brand = payload[EnvPayloadKey.brand] as? String else {
            Self.logger.error("r_action_env_will_switch_failed, payload: \(payload)")
            return .just(())
        }
        Self.logger.info("r_action_env_will_switch",
                         additionalData: ["env": futureEnv.description,
                                          "brand": brand],
                         method: .local)
        // 跨unit切换user时调用,（i.e. 用飞书登录lark账号）
        return rustSwitchEnv(futureEnv, brand: brand)
            .map({ (result: (DomainSettings, String)) -> Void in
                let settings = result.0
                let brand = result.1
                Self.logger.info("r_action_env_will_switch_succ", method: .local)
                // MultiGeo updated
                DomainSettingManager.shared.update(domains: settings, envType: futureEnv.type, unit: futureEnv.unit, brand: brand)
                ConfigurationManager.shared.switchEnv(futureEnv)
                return ()
            }).trace("RustSwitchEnv", params: [
                "env": "\(futureEnv)"
            ])
    }

    private func rustSwitchEnv(_ env: Env, brand: String) -> Observable<(DomainSettings, String)> {
        var request = RustPB.Basic_V1_SetEnvRequest()
        request.envType = .online /// 3.27.0起，无用字段
        // MultiGeo updated
        request.envV2 = makeEnvV2(env, brand: brand)
        request.syncDataStrategy = .tryLocal
        return client
            .sendAsyncRequestBarrier(request)
            .map { (response) -> SetEnvResponse in
                return response.response
            }
            .map { (resp) -> (DomainSettings, String) in
                return (resp.domainSettings, brand)
            }
            .catchError({ (error) -> Observable<(DomainSettings, String)> in
                let convertedError = SwitchEnvironmentError.rustSetEnvFailed(error.localizedDescription)
                Self.logger.error("r_action_rust_switch_env_error", error: convertedError)
                return .error(convertedError)
            })
    }

    // MultiGeo updated
    private func makeEnvV2(_ env: Env, brand: String) -> Basic_V1_InitSDKRequest.EnvV2 {
        var rustEnv = Basic_V1_InitSDKRequest.EnvV2()
        rustEnv.unit = env.unit
        rustEnv.type = env.type.transform()
        rustEnv.brand = brand
        return rustEnv
    }

}
