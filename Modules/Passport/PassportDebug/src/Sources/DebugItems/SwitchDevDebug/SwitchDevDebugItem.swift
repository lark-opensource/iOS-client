//
//  SwitchDevDebugItem.swift
//  PassportDebug
//
//  Created by ByteDance on 2022/7/25.
//

#if DEBUG || BETA || ALPHA

import Foundation
import LarkDebugExtensionPoint
import LarkAccountInterface
import EENavigator
import LarkEnv
import LarkContainer
import RoundedHUD
import LKCommonsLogging
import LarkStorage

class SwitchDevDebugItem: DebugCellItem {
    private let logger = Logger.log(SwitchDevDebugItem.self, category: "SwitchDevDebugItem")

    var title: String { return "切换 Dev 环境" }
    var detail: String { return EnvManager.env.description }

    private var accountService: AccountService
    @Provider var passportDebugService: PassportDebugService
    
    init(accountService: AccountService) {
        self.accountService = accountService
    }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let switchDevDebugVC = SwitchDevDebugController(accountService: accountService)
        switchDevDebugVC.modalPresentationStyle = .fullScreen
        Navigator.shared.present(switchDevDebugVC, from: debugVC)
    }
}

public final class PassportMockSwitchEnvInDebug: NSObject {

    @Provider static var accountService: AccountService
    static let envLogger = Logger.log(PassportMockSwitchEnvInDebug.self, category: "plog." + "Env.SwitchEnvironmentManager")

    @objc
    public class func mockSwitchToEnv(type: Int, unit: String, geo: String, brand: String) {
        if accountService.isLogin {
            accountService.relogin(
                conf: .debugSwitchEnv,
                onError: { error in
                    Self.envLogger.error("n_action_PassportMockSwitchEnvInDebug, error: \(error)")
                }, onSuccess: {
                    Self.envLogger.info("n_action_PassportMockSwitchEnvInDebug, will Switch")
                    Self.switchDevEnv(type: type, unit: unit, geo: geo, brand: brand)
                }, onInterrupt: {
                })
        } else {
            Self.envLogger.info("n_action_PassportMockSwitchEnvInDebug, direct Switch")
            let env = Env(unit: unit, geo: geo, type: Env.TypeEnum(rawValue: type) ?? .release)
            Self.switchDevEnv(type: type, unit: unit, geo: geo, brand: brand)
        }
    }
    
    // 1: release
    // 2: staging
    // 3: preRelease
    @objc
    public class func fetchEnvType() -> Int {
        return EnvManager.env.type.rawValue
    }
    
    // eu_nc: Mainland China
    // eu_ea: US
    // larksgaws: Singapore
    // boecn
    // boeva
    @objc
    public class func fetchEnvUnit() -> String {
        return EnvManager.env.unit
    }
    
    @objc
    public class func fetchEnvGeo() -> String {
        return EnvManager.env.geo
    }

    class func switchDevEnv(type: Int, unit: String, geo: String, brand: String) {
        guard let typeEnum = Env.TypeEnum(rawValue: type) else {
            Self.envLogger.error("n_action_PassportMockSwitchEnvInDebug, error: incorrect type")
            return
        }
        Self.envLogger.error("n_action_PassportMockSwitchEnvInDebug, succeeded")
        let env = Env(unit: unit, geo: geo, type: typeEnum)
        EnvManager.debugMenuUpdateEnv(env, brand: brand)

        // 创建qa专属文件夹
        let qaDir: IsoPath = .global.in(domain: Domain.biz.passport).build(.document).appendingRelativePath("qa")
        try? qaDir.createDirectoryIfNeeded()
        // BOE标识文件
        let boeTxt: IsoPath = qaDir.appendingRelativePath("BOE.txt")
        // 如果是切换到BOE环境，则写上对应文件
        if env.type == .staging {
            self.envLogger.info("n_action_PassportMockSwitchEnvInDebug env.type == .staging")
            if !boeTxt.exists {
                self.envLogger.info("n_action_PassportMockSwitchEnvInDebug boeTxt createFile")
                try? boeTxt.createFile()
            }
        } else {
            self.envLogger.info("n_action_PassportMockSwitchEnvInDebug env.type != .staging")
            if boeTxt.exists {
                self.envLogger.info("n_action_PassportMockSwitchEnvInDebug boeTxt removeItem")
                try? boeTxt.removeItem()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            exit(0)
        }
    }
}
#endif
