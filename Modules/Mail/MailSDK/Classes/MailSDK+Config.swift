//
//  MailSDK+Config.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/29.
//

import Foundation

// 需要暴露外部去set配置的一些方法。外部所有操作都通过mailSDK透传
extension MailSDKManager {
    public func setMailSDKAPI(_ mailAPI: MailSDKAPI) {
        MailModelManager.shared.mailAPI = mailAPI
    }
}
