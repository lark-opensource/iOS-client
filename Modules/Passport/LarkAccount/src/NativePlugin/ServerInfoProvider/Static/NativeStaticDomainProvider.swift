//
//  StaticDomainProvider.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/4.
//

import Foundation
import LarkAccountInterface
import LarkEnv

class NativeStaticDomainProvider: DomainProviderProtocol {
    func getDomain(_ key: DomainAliasKey) -> DomainValue {
        let val: String?
        switch key {
        case .api, .apiUsingPackageDomain, .passportAccounts, .passportAccountsUsingPackageDomain, .privacy, .device, .ttApplog, .passportTuring, .passportTuringUsingPackageDomain, .privacyUsingPackageDomain, .ttApplogUsingPackageDomain, .open:
            val = nil
        case .ttGraylog:
            switch PassportStore.shared.configEnv {
            case V3ConfigEnv.lark:
                val = CommonConst.euVAGrayLogDomain
            case V3ConfigEnv.feishu:
                val = CommonConst.euNCGrayLogDomain
            default:
                val = CommonConst.euNCGrayLogDomain
            }
        }
        return .init(value: val, provider: .nativeStaticSettings)
    }

    func asyncGetDomain(_ env: Env, brand: String, key: DomainAliasKey, completionHandler: @escaping (DomainValue) -> Void) {
        completionHandler(.init(value: nil, provider: .notFound))
    }
}
