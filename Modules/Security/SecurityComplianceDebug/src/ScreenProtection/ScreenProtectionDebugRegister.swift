//
//  ScreenProtectionDebugRegister.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2022/10/13.
//

import UIKit
import LarkSecurityComplianceInfra
import LarkSecurityCompliance
import LarkAccountInterface
import LarkContainer
import LarkEMM

final class ScreenProtectionDebugRegister: SCDebugModelRegister {
    
    let userResolver: UserResolver
    let permission: ScreenProtectionDebugPermission
    
    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
        self.permission = ScreenProtectionDebugPermission(resolver: resolver)
    }
    
    enum ScreenProtectionPermission: Int {
        case closed
        case open
    }
    
    struct ScreenProtectionDebugPermission {
        let resolver: UserResolver
        
        init(resolver: UserResolver) {
            self.resolver = resolver
        }
        
        var keyOfScreenProtection: String {
            let prefixKey = "key_of_screen_protection_vc"
            if let userService = try? resolver.resolve(assert: PassportUserService.self) {
                return prefixKey + "_" + userService.user.userID.md5()
            }
            return prefixKey
        }
        
        
        var current: ScreenProtectionPermission {
            let value = UserDefaults.standard.integer(forKey: keyOfScreenProtection)
            let permission = ScreenProtectionPermission(rawValue: value) ?? .closed
            return permission
        }

        var isOpen: Bool {
            return self.current == .open
        }

        var isClosed: Bool {
            return self.current == .closed
        }

        func store(_ permission: ScreenProtectionPermission) {
            UserDefaults.standard.set(permission.rawValue, forKey: keyOfScreenProtection)
            Logger.info("screen protection permission is \(permission)")
        }
    }
    
    
    func registModels() {
        guard let debugEntrance = try? userResolver.resolve(assert: SCDebugEntrance.self) else { return }
        debugEntrance.regist(section: .default) {
            SCDebugModel(cellTitle: "截屏录屏总开关", cellType: .switchButton, switchHandler: { [weak self] isOn in
                guard let self else { return }
                if isOn, self.permission.isClosed {
                    let service = try? self.resolver.resolve(assert: EMMDebugService.self)
                    service?.sendScreenProtectionBot()
                }
                self.permission.store(isOn ? .open : .closed)
                do {
                    let service = try? self.resolver.resolve(assert: EMMDebugService.self)
                    try service?.setScreenProtection(.default, enabled: isOn)
                } catch {
                    Logger.error("API ERROR: \(error)")
                }
                Logger.info("screen protection main switch \(isOn)")})
        }
        debugEntrance.regist(section: .default) {
            SCDebugModel(cellTitle: "截屏录屏imGroup开关", cellType: .switchButton, switchHandler: { [weak self] isOn in
                guard let self else { return }
                if isOn, self.permission.isClosed {
                    let service = try? self.resolver.resolve(assert: EMMDebugService.self)
                    service?.sendScreenProtectionBot()
                }
                do {
                    let service = try? self.resolver.resolve(assert: EMMDebugService.self)
                    try service?.setScreenProtection(.imGroup, enabled: isOn)
                } catch {
                    Logger.error("API ERROR: \(error)")
                }
                Logger.info("screen protection imGroup switch \(isOn)")
                
            })
        }
        debugEntrance.regist(section: .default) {
            SCDebugModel(cellTitle: "bot通知开关", cellType: .switchButton, switchHandler: { [weak self] isOn in
                guard let self else { return }
                if isOn {
                    let service = try? self.resolver.resolve(assert: EMMDebugService.self)
                    service?.sendScreenProtectionBot()
                }})
        }
    }
    
    
}
