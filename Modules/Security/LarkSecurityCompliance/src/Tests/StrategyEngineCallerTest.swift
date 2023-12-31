//
//  StrategyEngineCallerTest.swift
//  LarkSecurityCompliance-Unit-Tests
//
//  Created by ByteDance on 2023/9/25.
//

import XCTest
@testable import LarkSecurityCompliance
import LarkPolicyEngine
import LarkContainer
import LarkAccountInterface
import LarkSecurityComplianceInterface

let strategyEngineCaller: StrategyEngineCaller = StrategyEngineCaller()

class ObserverImp: LarkPolicyEngine.Observer {
    var flag: Int = 0
    func notify(event: Event) {
        flag = 1
    }
}

final class StrategyEngineCallerTest: XCTestCase {
    let observer = ObserverImp()
    
    func testStrategyEngineResgister() {
        let policyModels = [PointCutOperate.ccmExport(entityType: .doc,
                                                      operateTenantId: 1_111_111,
                                                      operateUserId: 1_111_111,
                                                      token: "VW9ddr5GLonn1JxMBGLbx7BOcCe",
                                                      ownerTenantId: nil, ownerUserId: nil,
                                                      tokenEntityType: nil).asModel()]
        strategyEngineCaller.register(observer: observer)
        var authResult = 0
        strategyEngineCaller.registerAuth { _ in
            authResult = 1
        }
        strategyEngineCaller.checkAuth(policyModels: policyModels, callTrigger: .constructor) { [weak self] _ in
            guard let self else {
                return
            }
            XCTAssertEqual(self.observer.flag, 1)
            XCTAssertEqual(authResult, 1)
        }
    }
    
}
