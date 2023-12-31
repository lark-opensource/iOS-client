//
//  RustDomainProvider.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/4.
//

import Foundation
import LarkSetting
import LarkAccountInterface
import LarkReleaseConfig
import LarkEnv
import RxSwift
import LarkRustClient
import RustPB
import LarkContainer

class RustDynamicDomainProvider: DomainProviderProtocol {

    private let disposeBag = DisposeBag()

    @Provider var rustClient: GlobalRustService

    func asyncGetDomain(_ env: Env, brand: String, key: DomainAliasKey, completionHandler: @escaping (DomainValue) -> Void) {
        guard let larkSettingDomainKey = ServerInfoProvider.transformToLarkSettingKey(key)?.rawValue else {
            completionHandler(.init(value: nil, provider: .notFound))
            return
        }

        //获取目标unit的did域名
        let domainField = "biz_domain_config"
        var rustEnv = Basic_V1_InitSDKRequest.EnvV2()
        rustEnv.unit = env.unit
        rustEnv.type = env.type.transform()
        rustEnv.brand = brand

        var request = RustPB.Settings_V1_GetCommonSettingsRequest()
        request.needDomain = true
        request.envV2 = rustEnv
        request.fields = [domainField]
        request.syncDataStrategy = .tryLocal

        rustClient
            .sendAsyncRequest(request)
            .map({ (response) -> RustPB.Settings_V1_GetCommonSettingsResponse in
                return response.response
            }).subscribe(onNext: { response in
                guard let domainConfigJson = response.settings[domainField],
                      let domainData = domainConfigJson.data(using: .utf8),
                      let domainSettings = try? JSONSerialization.jsonObject(with: domainData, options: []) as? [String: Any],
                      let applogDomain = (domainSettings[larkSettingDomainKey] as? [String])?.first else {

                    completionHandler(.init(value: nil, provider: .notFound))
                    return
                }
                completionHandler(.init(value: applogDomain, provider: .rustDynamicDomain))
            }, onError: { _ in
                completionHandler(.init(value: nil, provider: .notFound))
            }).disposed(by: self.disposeBag)
    }

    func getDomain(_ key: DomainAliasKey) -> DomainValue {
        let val: String?
        switch key {
        case .api:
            val = DomainSettingManager.shared.currentSetting[.api]?.first
        case .apiUsingPackageDomain:
            val = getHostUsingPackageDomain(.api)
        case .passportAccounts:
            val = DomainSettingManager.shared.currentSetting[.passportAccounts]?.first
        case .passportAccountsUsingPackageDomain:
            val = getHostUsingPackageDomain(.passportAccounts)
        case .ttGraylog:
            val = DomainSettingManager.shared.currentSetting[.ttGraylog]?.first
        case .privacy:
            val = DomainSettingManager.shared.currentSetting[.privacy]?.first
        case .device:
            val = DomainSettingManager.shared.currentSetting[.device]?.first
        case .ttApplog:
            val = DomainSettingManager.shared.currentSetting[.ttApplog]?.first
        case .ttApplogUsingPackageDomain:
            val = getHostUsingPackageDomain(.ttApplog)
        case .passportTuring:
            val = DomainSettingManager.shared.currentSetting[.passportTuring]?.first
        case .passportTuringUsingPackageDomain:
            val = getHostUsingPackageDomain(.passportTuring)
        case .privacyUsingPackageDomain:
            val = getHostUsingPackageDomain(.privacy)
        case .open:
            val = DomainSettingManager.shared.currentSetting[.openMG]?.first
        }
        return DomainValue(value: val, provider: .rustDynamicDomain)
    }

    /// 根据包环境而不是动态服务环境，获取缓存的域名，目前包含 .api 和 .passportAccounts 两种情况
    /// MultiGeo Updated: 根据包默认 unit 和 brand 组成 cacheKey
    private func getHostUsingPackageDomain(_ key: LarkSetting.DomainKey) -> String? {
        let env = EnvManager.getPackageEnv()
        let brand = ReleaseConfig.isLark ? TenantBrand.lark : TenantBrand.feishu

        let map = DomainSettingManager.shared.getDestinedDomainSetting(with: env, and: brand.rawValue)
        return map?[key]?.first
    }
}
