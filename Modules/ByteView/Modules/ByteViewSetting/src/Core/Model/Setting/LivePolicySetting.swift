//
//  LivePolicySetting.swift
//  ByteViewSetting
//
//  Created by wpr on 2023/12/7.
//

import Foundation

public struct PolicyURL {
    public let vcPrivacyPolicyUrl: String   //隐私协议
    public let vcTermsServiceUrl: String    //用户协议
    public let vcLivePolicyUrl: String      //直播协议

    public init(vcPrivacyPolicyUrl: String, vcTermsServiceUrl: String, vcLivePolicyUrl: String) {
        self.vcPrivacyPolicyUrl = vcPrivacyPolicyUrl
        self.vcTermsServiceUrl = vcTermsServiceUrl
        self.vcLivePolicyUrl = vcLivePolicyUrl
    }
}
