//
//  CrossUnitMiddleWare.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2020/4/25.
//

import Foundation
import LarkEnv
import LarkContainer

class CrossUnitMiddleWare: HTTPMiddlewareProtocol {

    @Provider var helper: V3APIHelper
    @Provider var tokenManager: PassportTokenManager

    private lazy var store = PassportStore.shared

    init() {}

    func config() -> [HTTPMiddlewareAspect: HTTPMiddlewarePriority] {
        [
            .error: .low
        ]
    }

    func handle<ResponseData: ResponseV3>(
        request: PassportRequest<ResponseData>,
        complete: @escaping () -> Void
    ) {
        complete()
//        guard case V3LoginError.badServerCode(let errorInfo)? = request.context.error,
//            case .needCrossUnit = errorInfo.type else {
//            complete()
//            return
//        }
//        guard let changeToUnit = V3.Step.getChangeToUnit(errorInfo.detail) else {
//            request.context.error = .badServerData
//            let msg = "V3InputCredentialVM: doCrossBoundary can not get env or changeToUnit"
//            HTTPClient.logger.error(msg)
//            complete()
//            return
//        }
//        let changeToEnv = V3.Step.getChangeToEnv(errorInfo.detail)
//        /// 直接更新环境
//        if let configEnv = changeToEnv {
//            HTTPClient.logger.info("cross unit update v3 config env: \(configEnv)")
//            store.configEnv = configEnv
//            envService.updateIsStdLark(configEnv == V3ConfigEnv.lark)
//        } else {
//            let msg = "not get v3config env from cross unit response: \(errorInfo.detail)"
//            HTTPClient.logger.error(msg)
//            assertionFailure(msg)
//        }
//        let env = Env.envFrom(unit: changeToUnit)
//        self.switchEnvManager.doLoginCrossUnit(
//            toEnv: env,
//            onSuccess: {
//                self.tokenManager.cleanToken()
//                UploadLogManager.shared.redirectService = true
//                request.context.needRetry = true
//                complete()
//            },
//            onFailure: { (error) in
//                request.context.error = error
//                complete()
//            })
    }
}
