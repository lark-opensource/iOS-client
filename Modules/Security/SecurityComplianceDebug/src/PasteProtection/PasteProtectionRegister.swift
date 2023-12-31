//
//  PasteProtectionRegister.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2022/10/13.
//

import Foundation
import EENavigator
import LarkContainer

final class PasteProtectionRegister: SCDebugModelRegister {
    let userResolver: UserResolver
    
    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }
    
    func registModels() {
        guard let debugEntrance = try? userResolver.resolve(assert: SCDebugEntrance.self) else { return }
        debugEntrance.regist(section: .deviceSecurity) {
            SCDebugModel(cellTitle: "Paste Protect", cellType: .normal, normalHandler: { [weak self] in
                guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                let vc = SCPasteboardDebugViewController(userResolver: userResolver)
                self.navigator.push(vc, from: currentVC)
            })
        }
    }
}
