//
//  PolicyEngineRegister.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2022/11/2.
//

import Foundation
import EENavigator
import LarkContainer

final class PolicyEngineRegister: SCDebugModelRegister {
    
    let userResolver: UserResolver
    
    required init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }

    func registModels() {
        guard let debugEntrance = try? userResolver.resolve(assert: SCDebugEntrance.self) else { return }
        debugEntrance.regist(section: .sncInfra) {
            SCDebugModel(
                cellTitle: "PolicyEngineTest",
                cellType: .normal,
                normalHandler: { [weak self] in
                    guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                    let vc = PolicyEngineDebugViewController(resolver: self.userResolver)
                    Navigator.shared.push(vc, from: currentVC)
                })
        }
    }
}
