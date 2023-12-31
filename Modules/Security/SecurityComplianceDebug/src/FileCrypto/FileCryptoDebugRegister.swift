//
//  FileCryptoDebugRegister.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2022/12/5.
//

import Foundation
import LarkSecurityComplianceInfra
import LarkSecurityCompliance
import EENavigator
import LarkContainer

final class FileCryptoDebugRegister: SCDebugModelRegister {
    let userResolver: UserResolver
    
    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }
    
    func registModels() {
        guard let debugEntrance = try? userResolver.resolve(assert: SCDebugEntrance.self) else { return }
        debugEntrance.regist(section: .default) {
            SCDebugModel(cellTitle: "移动端文件加密", cellType: .normal, normalHandler: { [weak self] in
                guard let self, let currentVC = self.userResolver.navigator.mainSceneTopMost else { return }
                let vc = FileCryptoDebugEntranceVC(resolver: self.userResolver)
                self.userResolver.navigator.push(vc, from: currentVC)
            })
        }
    }
}
