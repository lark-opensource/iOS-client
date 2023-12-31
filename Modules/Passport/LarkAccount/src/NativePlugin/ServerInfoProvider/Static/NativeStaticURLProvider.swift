//
//  StaticURLProvider.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/4.
//

import Foundation
import LarkAccountInterface

class NativeStaticURLProvider: URLProviderProtocol {

    func getUrl(_ key: URLKey) -> URLValue {
        let val: String?
        switch key {
        case .deviceId:
            switch PassportStore.shared.configEnv {
            case V3ConfigEnv.lark:
                val = CommonConst.euVADeviceIdUrl
            case V3ConfigEnv.feishu:
                val = CommonConst.euNCDeviceIdUrl
            default:
                val = CommonConst.euNCDeviceIdUrl
            }
        case .privacyPolicy, .serviceTerm, .userDeletionAgreement, .api, .apiUsingPackageDomain, .passportAccounts, .passportAccountsUsingPackageDomain, .open:
            val = nil
        }
        return .init(value: val, provider: .nativeStaticSettings)
    }
}
