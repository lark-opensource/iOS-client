//
//  SecurityPolicySceneContext.swift
//  LarkSecurityComplianceInterface
//
//  Created by ByteDance on 2023/7/28.
//

import Foundation
import LarkContainer
import LarkSecurityComplianceInfra

public struct SecurityPolicy {
    public typealias Identifier = String
    
    public enum Scene {
        case ccmFile(_ policyModels: [PolicyModel])
        
        public static func == (lf: SecurityPolicy.Scene, ri: SecurityPolicy.Scene) -> Bool {
            switch (lf, ri) {
            case(ccmFile, ccmFile):
                return true
            default:
                return false
            }
        }
        
        public static var allCases: [String] {
            return ["ccmFile"]
        }
    }
    
    public class SceneContext {
        public private(set) var scene: Scene
        public let identifier: Identifier
        public var userResolver: UserResolver
        public var onEventUpdate: (() -> Void)?
        
        public init(userResolver: UserResolver, scene: Scene, onEventUpdate: (() -> Void)? = nil) {
            self.userResolver = userResolver
            self.scene = scene
            self.identifier = UUID().uuidString
            self.onEventUpdate = onEventUpdate
            SCLogger.info("SceneContext init", additionalData: description)
        }
#if DEBUG || ALPHA
        public init(userResolver: UserResolver, scene: SecurityPolicy.Scene, identifier: String) {
            self.userResolver = userResolver
            self.scene = scene
            self.identifier = identifier
        }
#endif
        
        public var description: [String: String] {
            return [
                "scene": "\(scene)",
                "identifier": identifier
            ]
        }
    }
}

extension SecurityPolicy.SceneContext {
    public func beginTrigger() {
        let service = try? userResolver.resolve(assert: SceneEventService.self)
        service?.handleEvent(.start, context: self)
    }
    
    public func updateTrigger(_ scene: SecurityPolicy.Scene) {
        let service = try? userResolver.resolve(assert: SceneEventService.self)
        service?.handleEvent(.end, context: self)
        self.scene = scene
        service?.handleEvent(.start, context: self)
    }
    
    public func endTrigger() {
        let service = try? userResolver.resolve(assert: SceneEventService.self)
        service?.handleEvent(.end, context: self)
    }
    
    public func triggerEventUpdate() {
        guard let onEventUpdate = onEventUpdate else { return }
        onEventUpdate()
    }
}
