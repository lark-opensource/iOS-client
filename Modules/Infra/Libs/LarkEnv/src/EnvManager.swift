//
//  EnvManager.swift
//  LarkEnv
//
//  Created by Yiming Qu on 2021/1/24.
//
// Env 定义
// doc: https://bytedance.feishu.cn/docs/doccnH3rtofqXlwYfwh9hTLtKRu#rBHTs5
// LarkEnv设计
// doc: https://bytedance.feishu.cn/docs/doccn3LST2DrZ2uNvdorhPtgaAf

import EEAtomic
import Foundation
import LarkReleaseConfig
import LKCommonsLogging
import LKLoadable
import RxSwift

// swiftlint:disable missing_docs

public final class EnvManager {

    internal static let logger = Logger.log(EnvManager.self, category: "env.manager")

    /// 历史原因，这个 key 从 LarkAccount SwitchEnvironmentManager 迁移过来
    public static let tenantBrandKey = "Passport.SwitchEnvironmentManager.defaultTenantBrand"

    private static var debugEnvKeyV2: String { return "debugEnvKeyV2" }
    private static var isStdLarkKey: String { return "isStdLarkKey" }

    public static func validateCountryCodeIsChinaMainland(_ code: String) -> Bool {
        let lowercasedCode = code.lowercased()
        #if DEBUG || BETA || ALPHA
        return lowercasedCode == Geo.cn.rawValue || lowercasedCode == Geo.boeCN.rawValue
        #else
        return lowercasedCode == Geo.cn.rawValue
        #endif
    }
    
    public static func getDebugEnvironment() -> Env? {
        if let data = UserDefaults.standard.data(forKey: debugEnvKeyV2), let env = try? JSONDecoder().decode(Env.self, from: data) {
            return env
        }
        
        return nil
    }

    /// 本地缓存的环境配置
    /// - cached env conf
    public private(set) static var env: Env {
        get {
            if let data = UserDefaults.standard.data(forKey: debugEnvKeyV2) {
                do {
                    let info = try JSONDecoder().decode(Env.self, from: data)
                    return info
                } catch {
                    Self.logger.error("n_action_env_manager: GET - decode ud env failed with error: \(error)")
                }
            }
            // 使用包域名兜底
            let packageEnv = getPackageEnv()
            Self.logger.info("n_action_env_manager: use default package env: \(packageEnv)")
            Self.env = packageEnv
            return packageEnv
        }
        set {
            do {
                Self.logger.info("n_action_env_manager: save env to ud", additionalData: ["env": String(describing: newValue)])
                let data = try JSONEncoder().encode(newValue)
                UserDefaults.standard.set(data, forKey: debugEnvKeyV2)
            } catch {
                Self.logger.error("n_action_env_manager: SET - encode ud env failed with error: \(error)")
            }
        }
    }

    /// 获取包环境配置
    /// 包环境即打包完成后，app 本身自带的环境信息
    public static func getPackageEnv() -> Env {
        let configUnit = ReleaseConfig.defaultUnit ?? ""
        let configGeo = ReleaseConfig.defaultGeo ?? ""

        Self.logger.info("n_action_env_manager: get_package_env", additionalData: ["configUnit": configUnit, "configGeo": configGeo])

        #if DEBUG || BETA || ALPHA
        // ReleaseConfig.ReleaseChannel 不包含 pre 和 staging 的场景
        let isLarkPackage = ReleaseConfig.isLark
        let env: Env
        // 如果从未获取 env，默认是 release
        let currentType: Env.TypeEnum
        if let data = UserDefaults.standard.data(forKey: debugEnvKeyV2) {
            do {
                let info = try JSONDecoder().decode(Env.self, from: data)
                currentType = info.type
            } catch {
                currentType = .release
                Self.logger.error("n_action_env_manager: GET - decode ud env failed with error: \(error)")
            }
        } else {
            currentType = .release
        }
        switch currentType {
        case .staging:
            env = isLarkPackage ? Env.larkAppInStaging : Env.feishuAppInStaging
        case .preRelease:
            if configUnit.isEmpty || configGeo.isEmpty {
                env = isLarkPackage ? Env.larkAppInPre : Env.feishuAppInPre
            } else {
                env = Env(unit: configUnit, geo: configGeo, type: .preRelease)
            }
        case .release:
            if configUnit.isEmpty || configGeo.isEmpty {
                env = packageDebugLevel.transformToEnv()
            } else {
                env = Env(unit: configUnit, geo: configGeo, type: .release)
            }
        }

        return env

        #else

        if configUnit.isEmpty || configGeo.isEmpty {
            return packageDebugLevel.transformToEnv()
        } else {
            return Env(unit: configUnit, geo: configGeo, type: .release)
        }
        #endif
    }

    /// Debug菜单切换环境
    @available(*, deprecated, message: "MultiGeo: Will be removed soon.")
    public static func debugMenuUpdateEnv(_ env: Env, brand: String) {
        Self.logger.info("n_action_env_manager: debug update env", additionalData: ["env": String(describing: env)])
        EnvManager.env = env
        Self.updateCachedTenantBrand(brand)
    }

    public static func switchEnv(_ env: Env, brand: String) {
        self.env = env
        updateCachedTenantBrand(brand)
    }

    public static func switchEnv(_ env: Env, payload: [AnyHashable: Any]) -> Observable<Void> {
        let beforeOb = delegates(for: .before)
            .reduce(Observable.just(()), { (result, envDelegate) -> Observable<Void> in
                result.flatMap { _ -> Observable<Void> in
                    return envDelegate
                        .envWillSwitch(env, payload: payload)
                        .trace("EnvDelegate \(envDelegate.name) before")
                }
            })

        return beforeOb
            .trace(
                "SwitchEnv",
                params: [
                    "env": String(describing: env)
                ])
            .do(onNext: { _ in
                self.env = env

                if let brand = payload[EnvPayloadKey.brand] as? String {
                    Self.updateCachedTenantBrand(brand)
                }

                delegates(for: .after).forEach { (envDelegate) in
                    Self.logger.info("n_action_env_manager: EnvDelegate \(envDelegate.name) after")
                    envDelegate.envDidSwitch(.success((env, payload)))
                }
            }, onError: { error in
                delegates(for: .after).forEach { (envDelegate) in
                    Self.logger.error("n_action_env_manager: EnvDelegate \(envDelegate.name) after", error: error)
                    envDelegate.envDidSwitch(.failure(error))
                }
            })
                }

    // MARK: - Private
    private static let packageDebugLevel: DebugLevel = {
        DebugLevel(rawValue: ReleaseConfig.releaseChannel) ?? .release
    }()

    private static func updateCachedTenantBrand(_ brand: String) {
        UserDefaults.standard.set(brand, forKey: Self.tenantBrandKey)
        Self.logger.info("n_action_env_manager: update_brand: \(brand)")
    }

    private static let disposeBag = DisposeBag()

    private static func delegates(for aspect: EnvDelegateAspect) -> [EnvDelegate] {
        let allDelegateNames = factories.map({ $0.delegate.name })
        let filteredDelegates = factories
            .compactMap({ factory -> (delegate: EnvDelegate, priority: EnvDelegatePriority)? in
                if let priority = factory.delegate.config()[aspect] {
                    return (delegate: factory.delegate, priority: priority)
                } else {
                    return nil
                }
            })
            .sorted(by: { $0.priority > $1.priority })
            .map({ $0.delegate })
        Self.logger.info("n_action_env_manager: get delegates", additionalData: [
            "aspect": String(describing: aspect),
            "allDelegateNames": String(describing: allDelegateNames),
            "filteredDelegates": String(describing: filteredDelegates.map({ $0.name }))
        ])
        return filteredDelegates
    }

    /// EnvDelegate factories
    /// - 注册详见EnvDelegateRegistry
    private static var factories: [EnvDelegateFactory] {
        SwiftLoadable.startOnlyOnce(key: "LarkEnv_EnvDelegateRegistry_regist")
        return EnvDelegateRegistry.factories
    }
}

extension ObservableType {
    func trace(
        _ tag: String,
        params: [String: String] = [:]
    ) -> Observable<Self.Element> {
        EnvManager.logger.info("n_action_env_manager: [\(tag)] on begin ", additionalData: params)
        return self.do(onNext: { _ in
            EnvManager.logger.info("n_action_env_manager: [\(tag)] on next ", additionalData: params)
        }, onError: { error in
            EnvManager.logger.error(
                "n_action_env_manager: [\(tag)] on error ",
                additionalData: params,
                error: error
            )
        })
    }
}

// swiftlint:enable missing_docs
