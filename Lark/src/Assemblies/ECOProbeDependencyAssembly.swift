//
//  ECOProbeDependencyAssembly.swift
//  LarkOpenPlatform
//
//  Created by qsc on 2021/4/1.
//

import Foundation
import Swinject
import ECOProbe
import ECOInfra
import EEMicroAppSDK
import LarkAssembler
import LarkSetting
import LarkContainer

final class ECOProbeDependencyAssembly: LarkAssemblyInterface {
    init() {}

    func registContainer(container: Container) {
        container.register(OPProbeConfigDependency.self) { resolver in
            return OPProbeConfigDependencyImpl(resolver: resolver)
        }.inObjectScope(.user)
    }
}

/// FIXME: OPProbe 需要移除对 EMAAppEngine/EMAFeatureGating 的隐式调用依赖
final class OPProbeConfigDependencyImpl: NSObject, OPProbeConfigDependency {
    private let resolver: Resolver
    init(resolver: Resolver) {
        self.resolver = resolver
    }
    var isAfterLoginStage: Bool = false

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

    func readMinaConfig(for key: String) -> [String: Any] {
        guard isAfterLoginStage else {
            // 登录成功前始终返回空字典，防止出现登录前的死锁问题：Account -> OPMonitor -> FG -> Account
            return [:]
        }
        return EMAAppEngine.current()?.configManager?.minaConfig.getDictionaryValue(for: key) ?? [:]
    }
    func getRealTimeSetting(for key: String) -> [String: Any]? {
        return ECOConfig.service().getLatestDictionaryValue(for: key)
    }
}
