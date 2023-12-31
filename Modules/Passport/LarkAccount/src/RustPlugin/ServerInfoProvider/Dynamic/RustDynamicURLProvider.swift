//
//  RustDynamicURLProvider.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/4.
//

import Foundation
import LarkAppConfig
import LarkAccountInterface

class RustDynamicURLProvider: URLProviderProtocol {

    let rustDomainProvider = RustDynamicDomainProvider()

    func getUrl(_ key: URLKey) -> URLValue {
        let val: String?
        switch key {
        case .api:
            let domainVal = rustDomainProvider.getDomain(.api)
            if let domain = domainVal.value {
                val = "\(CommonConst.prefixHTTPS)\(domain)\(CommonConst.slant)"
            } else {
                val = nil
            }
        case .apiUsingPackageDomain:
            let domainVal = rustDomainProvider.getDomain(.apiUsingPackageDomain)
            if let domain = domainVal.value {
                val = "\(CommonConst.prefixHTTPS)\(domain)\(CommonConst.slant)"
            } else {
                val = nil
            }
        case .passportAccounts:
            let domainVal = rustDomainProvider.getDomain(.passportAccounts)
            if let domain = domainVal.value {
                val = "\(CommonConst.prefixHTTPS)\(domain)\(CommonConst.slant)"
            } else {
                val = nil
            }
        case .passportAccountsUsingPackageDomain:
            let domainVal = rustDomainProvider.getDomain(.passportAccountsUsingPackageDomain)
            if let domain = domainVal.value {
                val = "\(CommonConst.prefixHTTPS)\(domain)\(CommonConst.slant)"
            } else {
                val = nil
            }
        case .privacyPolicy:
            let domainVal = rustDomainProvider.getDomain(.privacy)
            if let url = PrivacyConfig.dynamicPrivacyURL {
                val = url
            } else if let domain = domainVal.value {
                val = "\(CommonConst.prefixHTTPS)\(domain)\(PrivacyConfig.privacySuffix)"
            } else {
                val = nil
            }
        case .serviceTerm:
            let domainVal = rustDomainProvider.getDomain(.privacy)
            if let url = PrivacyConfig.dynamicTermURL {
                val = url
            } else if let domain = domainVal.value {
                val = "\(CommonConst.prefixHTTPS)\(domain)\(PrivacyConfig.termsSuffix)"
            } else {
                val = nil
            }
        case .deviceId:
            let domainVal = rustDomainProvider.getDomain(.device)
            if let domain = domainVal.value {
                val = "\(CommonConst.prefixHTTPS)\(domain)\(CommonConst.slant)"
            } else {
                val = nil
            }
        case .userDeletionAgreement:
            let domainVal = rustDomainProvider.getDomain(.privacy)
            if let domain = domainVal.value {
                val = "\(CommonConst.prefixHTTPS)\(domain)\(PrivacyConfig.accountDeletionSuffix)"
            } else {
                val = nil
            }
        case .open:
            let domainVal = rustDomainProvider.getDomain(.open)
            if let domain = domainVal.value {
                val = "\(CommonConst.prefixHTTPS)\(domain)\(CommonConst.slant)"
            } else {
                val = nil
            }
        }
        return .init(value: val, provider: .rustDynamicDomain)
    }
}
