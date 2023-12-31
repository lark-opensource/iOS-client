//
//  NetworkControlRegister.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2023/3/31.
//

import Foundation
import EENavigator
import LarkContainer

final class NetworkControlRegister: SCDebugModelRegister {
    
    let userResolver: UserResolver
    
    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }
   
    func registModels() {
        guard let debugEntrance = try? userResolver.resolve(assert: SCDebugEntrance.self) else { return }
        debugEntrance.regist(section: .sncInfra) {
            SCDebugModel(
                cellTitle: "NetworkControlTest",
                cellType: .normal,
                normalHandler: { [weak self] in
                    guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                    let vc = NetworkControlEntranceViewController()
                    self.userResolver.navigator.push(vc, from: currentVC)
                }
            )
        }
    }
}
