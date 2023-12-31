//
//  NativeInjectURLProvider.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/5.
//

import Foundation
import LarkAccountInterface

// 兼容第一版SDK API

class NativeInjectURLProvider: URLProviderProtocol {
    func getUrl(_ key: URLKey) -> URLValue {
        let val: String?
        switch key {
        case .api, .apiUsingPackageDomain:
            if let url = PassportConf.shared.apiUrlProvider?() {
                val = url + "/"
            } else {
                val = nil
            }
        case .passportAccounts, .passportAccountsUsingPackageDomain, .open:
            val = nil
        case .privacyPolicy:
            val = PassportConf.shared.privacyPolicyUrlProvider?()
        case .serviceTerm:
            val = PassportConf.shared.serviceTermUrlProvider?()
        case .deviceId:
            val = PassportConf.shared.deviceIdUrlProvider?()
        case .userDeletionAgreement:
            val = PassportConf.shared.userDeletionAgreementUrlProvider?()
        }
        return .init(value: val, provider: .oldRuntimeInjectConfig)
    }

}
