//
//  CcmFileEventHandlerV2.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/7.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import LarkContainer

extension SecurityPolicyV2 {
    class CcmFileEventHandler: BizSceneEventHandler {
        var sceneContext: SecurityPolicy.SceneContext
        let userResolver: UserResolver
        private var cache: SecurityPolicyCacheService?
        var timer: SCTimer
        let dlpPeriodOfValidity: Int
        let dlpmanager: DLPValidateService?

        init(resolver: UserResolver, sceneContext: SecurityPolicy.SceneContext) {
            userResolver = resolver
            self.sceneContext = sceneContext
            let settings = try? userResolver.resolve(assert: SCSettingService.self)
            dlpPeriodOfValidity = settings?.int(SCSettingKey.dlpPeriodOfValidity) ?? 10 * 60
            dlpmanager = try? userResolver.resolve(assert: DLPValidateService.self)
            timer = SCTimer(config: TimerCongfig(timerInterval: dlpPeriodOfValidity))
            timer.handler = { [weak self] in
                guard let self else { return }
                guard case .ccmFile(let policyModels) = self.sceneContext.scene else { return }
                self.dlpmanager?.preValidateDLP(policyModels: policyModels, completed: { results in
                    SCLogger.info("CcmFileEventHandler update policyModels")
                    let isCredible = results.contains(where: { (_, value) in
                        value.isCredible
                    })
                    guard isCredible else {
                        SCLogger.info("dlp pre validate results are downgrade")
                        return
                    }
                    sceneContext.triggerEventUpdate()
                })
            }
            SCLogger.info("CcmFileEventHandler init")
        }

        deinit {
            SCLogger.info("CcmFileEventHandler deinit")
            stop()
        }

        func start() {
            precheck()
            timer.startTimer()
        }

        func stop() {
            timer.stopTimer()
        }

        func precheck() {
            guard case .ccmFile(let policyModels) = sceneContext.scene else {
                assertionFailure("ccmfile scene: policymodels are nil")
                return
            }
            let tokens = policyModels.map({ policyModel in
                policyModel.getToken()
            })
            let uniqueElement = Set(tokens)
            guard uniqueElement.count == 1 && uniqueElement.first != nil else {
                assertionFailure("ccm file entity token must be same")
                return
            }
        }
    }
}
