//
//  CommonSettingProvider.swift
//  LarkMail
//
//  Created by tefeng liu on 2020/5/14.
//

import Foundation
import MailSDK
import LarkSDKInterface
import RxSwift
import Swinject
import LKCommonsLogging
import BootManager
import AppContainer

class CommonSettingProvider {
    let logger = Logger.log(CommonSettingProvider.self, category: "Module.Mail")

    private var configurationAPI: ConfigurationAPI? {
        return try? resolver.resolve(assert: ConfigurationAPI.self)
    }

    private var resolver: Resolver {
        return BootLoader.container
    }
    private let disposeBag = DisposeBag()
    private var config: [String: Any] = [:]
    private var helpCenterConfig: [String: Any] = [:]
    private var customerServiceConfig: [String: Any] = [:]
    private var mailMixSearchConfig: [String: Any] = [:]

    private var orginalConfig: [String : String] = [:]

    static let shared: CommonSettingProvider = CommonSettingProvider()

    init() {

    }

    func fetchSetting() {
        let fields = MailSettingKey.allCases.map({ return $0.rawValue })
        configurationAPI?.fetchSettingsRequest(fields: fields).subscribe(onNext: { [weak self] (config) in
            guard let `self` = self else {
                return
            }
            self.orginalConfig = config
            DispatchQueue.global().async { [weak self] in
                self?.handleSettingData(config: config)
            }
            }, onError: { [weak self] (error) in
                self?.logger.error("CommonSettingProvider fetchSetting error \(error)")
            }).disposed(by: disposeBag)
    }

    func handleSettingData(config: [String: String]) {
        if let settingJson = config[MailSettingKey.mailSettingKey.rawValue],
           let data = settingJson.data(using: .utf8),
           let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            DispatchQueue.main.async {
                self.config = jsonDict
            }
        }
        if let helpCenterJson = config[MailSettingKey.helpCenterLinkKey.rawValue],
           let helpCenterData = helpCenterJson.data(using: .utf8),
           let helpCenterJsonDict = try? JSONSerialization.jsonObject(with: helpCenterData, options: []) as? [String: Any] {
            DispatchQueue.main.async {
                self.helpCenterConfig = helpCenterJsonDict
            }
        }
        if let customServiceJson = config[MailSettingKey.customerServiceLinkKey.rawValue],
           let customServiceData = customServiceJson.data(using: .utf8),
           let customServiceJsonDict = try? JSONSerialization.jsonObject(with: customServiceData, options: []) as? [String: Any] {
            DispatchQueue.main.async {
                self.customerServiceConfig = customServiceJsonDict
            }
        }
        if let mailMixSearchJson = config[MailSettingKey.mailMixSearchConfigKey.rawValue],
           let mailMixSearchData = mailMixSearchJson.data(using: .utf8),
           let mailMixSearchJsonDict = try? JSONSerialization.jsonObject(with: mailMixSearchData, options: []) as? [String: Any] {
            DispatchQueue.main.async {
                self.mailMixSearchConfig = mailMixSearchJsonDict
            }
        }
    }
}

extension CommonSettingProvider: MailSDK.CommonSettingProxy {
    func stringValue(key: String) -> String? {
        if let str = self.config[key] as? String, !str.isEmpty {
            return str
        } else if let str = self.helpCenterConfig[key] as? String, !str.isEmpty {
            return str
        } else if let str = self.customerServiceConfig[key] as? String, !str.isEmpty {
            return str
        } else {
            return nil
        }
    }

    func IntValue(key: String) -> Int? {
        if let int = self.config[key] as? Int {
            return int
        } else if let int = self.mailMixSearchConfig[key] as? Int {
            return int
        } else {
            return nil
        }
    }

    func floatValue(key: String) -> Float? {
        return self.config[key] as? Float
    }

    func arrayValue(key: String) -> [Any]? {
        return self.config[key] as? [Any]
    }

    func originalSettingValue(configName: MailSettingKey) -> String? {
        return self.orginalConfig[configName.rawValue]
    }
}
