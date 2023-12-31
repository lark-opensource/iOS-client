//
//  EncryptionUpgradeDebugRegister.swift
//  SecurityComplianceDebug
//
//  Created by AlbertSun on 2023/5/25.
//

import Foundation
import LarkContainer
import LarkSecurityCompliance

final class EncryptionUpgradeDebugRegister: SCDebugModelRegister {
    let userResolver: UserResolver
    
    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }
    
    func registModels() {
        guard let debugEntrance = try? userResolver.resolve(assert: SCDebugEntrance.self) else { return }
        debugEntrance.regist(section: .encryptionUpgrade) { [weak self] in
            SCDebugModel(cellTitle: "下次冷启进入升级",
                                         cellType: .switchButton,
                                         isSwitchButtonOn: self?.isRekeySwitchButtonOn() ?? false,
                                         switchHandler: { [weak self] isOn in
                let service = try? self?.resolver.resolve(assert: SCDebugService.self)
                service?.updateRekeyTokensOnDebugSwitch(isOn)
            })
        }
        
        debugEntrance.regist(section: .encryptionUpgrade) { [weak self] in
            SCDebugModel(cellTitle: "mock升级失败",
                                         cellType: .switchButton,
                                         isSwitchButtonOn: self?.isMockFailSwitchButtonOn() ?? false,
                                         switchHandler: { [weak self] isOn in
                let service = try? self?.resolver.resolve(assert: SCDebugService.self)
                service?.mockRekeyFailure(isOn)
            })
        }
    }
                       
    private func isRekeySwitchButtonOn() -> Bool {
        let service = try? resolver.resolve(assert: SCDebugService.self)
        return service?.isRekeyTokenOn() ?? false
    }
    
    private func isMockFailSwitchButtonOn() -> Bool {
        let service = try? resolver.resolve(assert: SCDebugService.self)
        return service?.isMockRekeyFailureOn() ?? false
    }
}
