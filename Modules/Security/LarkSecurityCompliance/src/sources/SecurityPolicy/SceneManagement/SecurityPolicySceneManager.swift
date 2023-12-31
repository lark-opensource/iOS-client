//
//  SceneManager.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/7/28.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkContainer
import LarkSecurityComplianceInfra

extension SecurityPolicy {
    public class EventManager: SceneEventService {
        @SafeWrapper var sceneContexts: [SceneContext]
        @SafeWrapper var sceneHandlers: [String: SceneEventHandler]
        let userResolver: UserResolver
        let enableDlpMigrate: Bool
        let enableCcmDlp: Bool
        init(userResolver: UserResolver) {
            self.userResolver = userResolver
            sceneHandlers = [:]
            sceneContexts = []
            let service = try? userResolver.resolve(assert: SCFGService.self)
            enableDlpMigrate = service?.realtimeValue(SCFGKey.enableDlp) ?? false
            enableCcmDlp = service?.realtimeValue(SCFGKey.enableCcmDlp) ?? false
        }
        
        public func handleEvent(_ trigger: LarkSecurityComplianceInterface.Trigger, context: LarkSecurityComplianceInterface.SecurityPolicy.SceneContext) {
            var additionalData: [String: String] = context.description
            guard enableDlpMigrate else {
                additionalData["fail_reason"] = "FG disabled, enableDlp: \(enableDlpMigrate)"
                SCLogger.info("SceneManager: handle event faile", additionalData: additionalData)
                return
            }
            additionalData["trigger"] = trigger.rawValue
            SCMonitor.info(business: .security_policy, eventName: "scene_event", category: additionalData)
            SCLogger.info("SceneManager: handle event", additionalData: additionalData)
            switch trigger {
            case .start:
                startHandler(context)
            case .end:
                removeHandler(context.identifier)
            case .immediately:
                let handler = createHandler(context)
                handler?.execute()
            default:
                additionalData["fail_reason"] = "no match trigger"
                SCLogger.error("SceneManager: handle event faild", additionalData: additionalData)
            }
        }
        
        private func startHandler(_ context: SceneContext) {
            let hasTrigger = sceneHandlers.contains(where: { (key, _) in
                key == context.identifier
            })
            var additional = context.description
            guard !hasTrigger else {
                additional["fail_reason"] = "has triggered"
                SCLogger.info("SceneContext start failed", additionalData: additional)
                return
            }
            guard let handler = createHandler(context)  else {
                additional["fail_reason"] = "create handler failed"
                SCLogger.info("SceneContext start failed", additionalData: additional)
                return
            }
            sceneContexts.append(context)
            sceneHandlers[context.identifier] = handler
            handler.start()
            SCLogger.info("SceneContext start success", additionalData: additional)
        }
        
        private func removeHandler(_ identifier: String) {
            let handler = sceneHandlers[identifier]
            handler?.stop()
            sceneHandlers.removeValue(forKey: identifier)
            sceneContexts.removeAll { sceneContext in
                sceneContext.identifier == identifier
            }
            SCLogger.info("SceneContext remove success", additionalData: ["identifier": identifier])
        }
        
        private func createHandler(_ sceneContext: SecurityPolicy.SceneContext) -> SceneEventHandler? {
            switch sceneContext.scene {
            case .ccmFile(_):
                guard enableCcmDlp else { return nil }
                let handler = CcmFileEventHandler(resolver: userResolver, sceneContext: sceneContext)
                return handler
            }
        }
    }
}
