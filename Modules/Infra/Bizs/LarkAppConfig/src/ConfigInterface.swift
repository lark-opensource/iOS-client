//
//  ConfigInterface.swift
//  LarkAppConfig
//
//  Created by 李晨 on 2019/11/14.
//

import Foundation
import RxSwift
import RustPB
import LarkEnv
import LarkSetting

// swiftlint:disable missing_docs
public typealias Env = LarkEnv.Env
public typealias EnvType = Basic_V1_InitSDKRequest.EnvType
public typealias InitSettingKey = DomainKey
public typealias InitSettings = RustPB.Basic_V1_DomainSettings

public typealias DomainSettingsMap = [DomainKey: [String]]
public typealias FeatureSwitchsMap = [String: [String: String]]

public protocol AppConfiguration {
    // prifix
    var larkPrefix: String { get }
    var h5JSSDKPrefix: String { get }

    // session config
    var mainDomains: [String] { get }
    var mainDomain: String { get }
    var cookieDomains: [String] { get }
    func register(cookieDomainAlias: DomainKey)
    func unregister(cookieDomainAlias: DomainKey)

    func switchEnv(_ env: Env)
    var envSignalV2: Observable<Env> { get }

    @available(*, deprecated, message: "Please use DomainSettingManager.shared.currentSetting, will remove")
    var domainSettings: DomainSettingsMap { get }

    @available(*, deprecated, message: "Please use DomainSettingManager.shared.currentSetting, will remove")
    var settings: [InitSettingKey: [String]] { get }
}
// swiftlint:enable missing_docs
