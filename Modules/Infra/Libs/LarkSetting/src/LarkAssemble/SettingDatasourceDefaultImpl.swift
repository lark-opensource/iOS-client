//
//  SettingDatasourceDefaultImpl.swift
//  LarkSetting
//
//  Created by 王元洵 on 2022/7/8.
//

import Foundation
import LarkRustClient
import LarkContainer
import RustPB
import RxSwift
import Swinject
import LKCommonsLogging
import EEAtomic
import LarkAccountInterface
import LarkEnv

final class SettingDatasourceDefaultImpl {
    private static let logger = Logger.log(SettingDatasourceDefaultImpl.self, category: "SettingDatasource")
    private func rustService(with id: String) -> RustService? {
        try? Container.shared.getUserResolver(userID: id, type: .both).resolve(type: RustService.self)
    }

    private func globalRustService() -> GlobalRustService? {
        try? Container.shared.resolve(assert: GlobalRustService.self)
    }

    private func globalFeatureGatingService() -> GlobalFeatureGatingService? {
        try? Container.shared.resolve(assert: GlobalFeatureGatingService.self)
    }

    private func getEnvV2() -> Basic_V1_InitSDKRequest.EnvV2? {
        let env = EnvManager.env
        guard let brand = Container.shared.resolve(LarkAccountInterface.AccountService.self)?.foregroundTenantBrand.rawValue,
            let envType = Basic_V1_InitSDKRequest.EnvV2.TypeEnum.init(rawValue: env.type.rawValue) else { return nil }
        let geo = AccountServiceAdapter.shared.foregroundUserGeo
        var rustEnv = Basic_V1_InitSDKRequest.EnvV2()
        rustEnv.brand = brand
        rustEnv.geo = geo
        rustEnv.unit = env.unit
        rustEnv.type = envType
        return rustEnv
    }
}

extension SettingDatasourceDefaultImpl: SettingDatasource {
    func refetchSingleSetting(with id: String, and key: String) {
        var request = RustPB.Settings_V1_GetUserSettingsRequest()
        request.fields = [key]
        request.needDomain = false
        request.syncDataStrategy = .local
        
        _ = rustService(with: id)?
            .sendAsyncRequest(request)
            .subscribe(onNext: { (response: Settings_V1_GetUserSettingsResponse) in
                guard let settingValue = response.settings[key], let globalSettingService = try? Container.shared.resolve(type: GlobalSettingService.self)
                else { return }
                globalSettingService.updateSettingValue(with: id, and: key, value: settingValue)
            })
    }

    func fetchSetting(resolver: UserResolver) {
        // 1.用户态配置
        let id = resolver.userID
        var request = RustPB.Settings_V1_GetUserSettingsRequest()
        var userSettingKeys = SettingStorage.userSettingKeyNeedFetched(with: id)
        request.fields = userSettingKeys
        request.needDomain = true
        request.syncDataStrategy = .local
        Self.logger.debug("start fetch user settings userID: \(id)")
        _ = rustService(with: id)?
            .sendAsyncRequest(request)
            .subscribe(onNext: { (response: Settings_V1_GetUserSettingsResponse) in
                if let globalSettingService = try? Container.shared.resolve(type: GlobalSettingService.self) {
                    globalSettingService.settingUpdate(settings: response.settings, id: id, sync: false)
                }
                if response.hasDomains, let userDomainService = try? resolver.resolve(assert: UserDomainService.self) {
                    userDomainService.updateUserDomainSetting(
                        new: DomainSettingManager.toDomainSettings(domains: response.domains)
                    )
                }
            })

        // 2.全局按用户规则灰度的FG
        var globalUserFeatureGatingRequest = RustPB.Settings_V1_GetUserSettingsRequest()
        guard let userFeatureGatingService = try? resolver.resolve(type: FeatureGatingService.self) else {
            return
        }
        let globalFGKeys = userFeatureGatingService.getAllUserGlobalFeatureGatingKeysNeedFetch()
        globalUserFeatureGatingRequest.fields = globalFGKeys
        globalUserFeatureGatingRequest.syncDataStrategy = .local
        globalUserFeatureGatingRequest.needDomain = false
        Self.logger.debug("fetch globalUserFeatureGatingRequest keys: \(globalUserFeatureGatingRequest.fields)")
        guard !globalUserFeatureGatingRequest.fields.isEmpty else { return }
        _ = rustService(with: id)?
            .sendAsyncRequest(globalUserFeatureGatingRequest)
            .subscribe(onNext: { (response: Settings_V1_GetUserSettingsResponse) in
                let globalUserFeatureGatings = response.settings
                Self.logger.debug("globalUserFeatureGatings keys in response: \(globalUserFeatureGatings.keys)")
                let boolKeyValuePairs = globalUserFeatureGatings.filter {
                    let value = $0.value.lowercased()
                    return value == "true" || value == "false"
                }.mapValues {
                    $0.lowercased() == "true"
                }
                userFeatureGatingService.updateUserGlobalFeatureGatings(new: boolKeyValuePairs)
            })
    }

    func fetchCommonSetting(envV2: Basic_V1_InitSDKRequest.EnvV2) {
        // 1.全局配置
        Self.logger.debug("start fetchCommonSetting")
        var commonSettingsRequest = RustPB.Settings_V1_GetCommonSettingsRequest()
        commonSettingsRequest.fields = SettingStorage.commonSettingKeyNeedFetched()
        commonSettingsRequest.syncDataStrategy = .local
        commonSettingsRequest.needDomain = true
        commonSettingsRequest.envV2 = envV2
        let globalRustService = globalRustService()
        globalRustService?
            .sendAsyncRequest(commonSettingsRequest)
            .subscribe(onNext: { (response: Settings_V1_GetCommonSettingsResponse) in
                let commonSettings = response.settings
                Self.logger.debug("commonSettings is: \(commonSettings.keys)")
                SettingStorage.commonSettings.updateCommonSetting(commonSettings)
                if response.hasDomains {
                    Self.logger.debug("domainSettings received from commonSettings")
                    let type: Env.TypeEnum
                    switch envV2.type {
                    case .release:
                        type = .release
                    case .staging:
                        type = .staging
                    case .preRelease:
                        type = .preRelease
                    @unknown default:
                        type = .release
                    }
                    DomainSettingManager.shared.update(
                        domains: response.domains, 
                        envType: type,
                        unit: envV2.unit, 
                        brand: envV2.brand
                    )
                }
            })

        var globalFeatureGatingRequest = RustPB.Settings_V1_GetCommonSettingsRequest()
        
        // 2.全局按设备维度灰度的FG
        // 是否weak @fengkebang todo
        guard let globalFeatureGatingService = self.globalFeatureGatingService() else { return }
        globalFeatureGatingRequest.fields = globalFeatureGatingService.getGlobalFeatureGatingKeysNeedFetch()
        globalFeatureGatingRequest.syncDataStrategy = .local
        globalFeatureGatingRequest.needDomain = false
        globalFeatureGatingRequest.envV2 = envV2
        Self.logger.debug("fetch globalFeatureGatingRequest keys: \(globalFeatureGatingRequest.fields)")
        guard !globalFeatureGatingRequest.fields.isEmpty else { return }
        globalRustService?
            .sendAsyncRequest(globalFeatureGatingRequest)
            .subscribe(onNext: { (response: Settings_V1_GetCommonSettingsResponse) in
                let globalFeatureGatings = response.settings
                Self.logger.debug("globalFeatureGatings keys in response: \(globalFeatureGatings.keys)")
                let boolKeyValuePairs = globalFeatureGatings.filter {
                    let value = $0.value.lowercased()
                    return value == "true" || value == "false"
                }.mapValues {
                    $0.lowercased() == "true"
                }
                globalFeatureGatingService.update(new: boolKeyValuePairs)
            })
    }
}

