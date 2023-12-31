//
//  AppLockDebugRegister.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2022/11/21.
//

import Foundation
import EENavigator
import LarkSecurityComplianceInfra
import LarkContainer

final class AppLockDebugRegister: SCDebugModelRegister {
    
    let userResolver: UserResolver
    
    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }

    func registModels() {
        guard let debugEntrance = try? userResolver.resolve(assert: SCDebugEntrance.self) else { return }

        debugEntrance.registRedirectorForSection(section: .appLock) { _, _ in
            guard let fromVC = self.userResolver.navigator.mainSceneTopMost,
                  let url = URL(string: "//client/mine/AppLockSetting") else { return }
            self.navigator.push(url, from: fromVC)
        }
    }
}
