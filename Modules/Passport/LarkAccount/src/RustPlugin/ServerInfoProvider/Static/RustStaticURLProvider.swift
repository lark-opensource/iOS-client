//
//  RustStaticURLProvider.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/4.
//

import Foundation
import LarkAppConfig
import LarkAccountInterface

class RustStaticURLProvider: URLProviderProtocol {

    func getUrl(_ key: URLKey) -> URLValue {
        let val: String?
        switch key {
        case .deviceId, .api, .apiUsingPackageDomain, .passportAccounts, .passportAccountsUsingPackageDomain, .open:
            /// 默认配置没有这两个URL， 需要外部注入
            val = nil
        case .privacyPolicy:
            val = PrivacyConfig.privacyURL
        case .serviceTerm:
            val = PrivacyConfig.termsURL
        case .userDeletionAgreement:
            val = PrivacyConfig.accountDeletionURL
        }
        return .init(value: val, provider: .rustStaticSettings)
    }
}
