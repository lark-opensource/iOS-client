//
//  MockDependencies.swift
//  LarkLaunchGuideDev
//
//  Created by Miaoqi Wang on 2020/4/2.
//

import Foundation
import UIKit
import LarkRustClient
import LKLaunchGuide
import LarkAppConfig
import RxSwift
import Swinject

struct MockAppConfiguration: AppConfiguration {
    var env: Env = ConfigurationManager.shared.env

    var type: Env.TypeEnum = .release

    var envSignalV2: Observable<Env> = .just(ConfigurationManager.shared.env)

    func switchEnv(_ env: Env, settings: InitSettings) {}

    var envType: EnvType = .staging
    var documentPath: URL = URL(string: "https://www.feishu.cn")!
    var globalLogPath: URL = URL(string: "https://www.feishu.cn")!
    var relativeLogPath: String = ""
    var clientLogPath: String = ""
    var isStaging: Bool = true
    var isOversea: Bool = false
    var reportUrl: String = ""
    var loginHost: String = ""
    var webviewAuthURL: String = ""
    var h5JSSDKConfigURLStr: String = ""
    var sessionName: String = ""
    var openSessionName: String = ""
    var bearSessionName: String = ""
    var mainDomains: [String] = []
    var mainDomain: String = ""
    var cookieDomains: [String] = []
    var settings: DomainSettingsMap = [:]
    var settingsObservable: Observable<DomainSettingsMap> = .just([:])
    var featureSwitchs: FeatureSwitchsMap = [:]
    var featureSwitchsObservable: Observable<FeatureSwitchsMap> = .just([:])
    var result: Observable<AsynGetInitSettingStatus> = .just(.notTriger)
    var envSignal: Observable<EnvType> = .just(.staging)

    func addContactURL(_ token: String) -> String { return "" }
    func switchEnv(_ env: EnvType, settings: InitSettings) {}
    func asyncGetInitSetting() {}
    func register(cookieDomainAlias: InitSettingKey) {}
    func unregister(cookieDomainAlias: InitSettingKey) {}
}
