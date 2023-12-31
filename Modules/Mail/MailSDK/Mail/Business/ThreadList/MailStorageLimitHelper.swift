//
//  MailStorageLimitHelper.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/4/2.
//

import Foundation
import EENavigator

class MailStorageLimitHelper {
    static func contactServiceConsultant(from: EENavigator.NavigatorFrom, navigator: Navigatable) {
        guard let configString = ProviderManager.default.commonSettingProvider?.stringValue(key: "customer_service_url"),
              let url = URL(string: configString),
              url.mail.canOpen(navigator: navigator) else {
            return
        }
        navigator.push(url, context: ["from": "mail"], from: from)
    }
}
