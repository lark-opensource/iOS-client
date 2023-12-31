//
//  SecurityPolicySceneTest.swift
//  LarkSecurityCompliance-Unit-Tests
//
//  Created by ByteDance on 2023/9/25.
//

import XCTest
import LarkSecurityComplianceInterface
import LarkAccountInterface
import LarkContainer
@testable import LarkSecurityCompliance

final class SecurityPolicySceneTest: XCTestCase {
    let userResolver: UserResolver = Container.shared.getCurrentUserResolver()

    func testSceneCreateAnd() throws {
        guard let userService = try? userResolver.resolve(assert: PassportUserService.self),
              let sceneManager = try? userResolver.resolve(assert: SceneEventService.self) as? SecurityPolicy.EventManager else {
            return
        }
        let policyModel = PointCutOperate.ccmExport(entityType: .doc, operateTenantId: Int64(userService.user.tenant.tenantID) ?? 0,
                                                    operateUserId: Int64(userService.user.userID) ?? 0, token: "VW9ddr5GLonn1JxMBGLbx7BOcCe",
                                                    ownerTenantId: nil, ownerUserId: nil, tokenEntityType: nil).asModel()
        let sceneContext = SecurityPolicy.SceneContext(userResolver: userResolver, scene: .ccmFile([policyModel]))
        sceneContext.beginTrigger()
        if sceneManager.enableDlpMigrate && sceneManager.enableCcmDlp {
            XCTAssertTrue(sceneManager.sceneContexts.contains(where: { context in
                context.identifier == sceneContext.identifier
            }))
            XCTAssertTrue(sceneManager.sceneHandlers.contains(where: { (identifier, _) in
                identifier == sceneContext.identifier
            }))
        } else {
            XCTAssertFalse(sceneManager.sceneContexts.contains(where: { context in
                context.identifier == sceneContext.identifier
            }))
            XCTAssertFalse(sceneManager.sceneHandlers.contains(where: { (identifier, _) in
                identifier == sceneContext.identifier
            }))
        }
         
        sceneContext.endTrigger()
        XCTAssertFalse(sceneManager.sceneContexts.contains(where: { context in
            context.identifier == sceneContext.identifier
        }))
        XCTAssertFalse(sceneManager.sceneHandlers.contains(where: { (identifier, _) in
            identifier == sceneContext.identifier
        }))
    }
}
