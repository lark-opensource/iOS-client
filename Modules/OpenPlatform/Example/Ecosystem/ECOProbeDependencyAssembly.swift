//
//  ECOProbeDependencyAssembly.swift
//  Ecosystem
//
//  Created by qsc on 2021/4/1.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import Swinject
import ECOProbe
import EEMicroAppSDK
import ECOInfra
import LarkAssembler
import LarkSetting

class ECOProbeDependencyAssembly: LarkAssemblyInterface {
    func registContainer(container: Swinject.Container) {
        container.register(OPProbeConfigDependency.self) { _ in
            return OPProbeConfigDependencyImpl()
        }.inObjectScope(.user)
    }
}

class OPProbeConfigDependencyImpl: NSObject, OPProbeConfigDependency {
    var isAfterLoginStage = false

    func readMinaConfig(for key: String) -> [String : Any] {
        guard isAfterLoginStage else {
            // 登录成功前始终返回空字典，防止出现登录前的死锁问题：Account -> OPMonitor -> FG -> Account
            return [:]
        }
        return EMAAppEngine.current()?.configManager?.minaConfig.getDictionaryValue(for: key) ?? [:]
    }

    func getFeatureGatingBoolValue(for key: String) -> Bool {
        guard isAfterLoginStage else {
            // 登录成功前始终返回 False，防止出现登录前的死锁问题：Account -> OPMonitor -> FG -> Account
            return false
        }
        return EMAFeatureGating.boolValue(forKey: key)
    }
    
    func getFeatureGatingBoolValueFastly(for key: String) -> Bool {
        guard isAfterLoginStage else {
            // 登录成功前始终返回 False，防止出现登录前的死锁问题：Account -> OPMonitor -> FG -> Account
            return false
        }
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key))
    }
    
    func getRealTimeSetting(for key: String) -> [String: Any]? {
        return ECOConfig.service().getLatestDictionaryValue(for: key)
    }
}
