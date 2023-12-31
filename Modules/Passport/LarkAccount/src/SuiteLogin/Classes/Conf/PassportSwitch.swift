//
//  SuiteLoginSwitchConfiguration.swift
//  SuiteLogin
//
//  Created by quyiming on 2019/11/25.
//

import Foundation
import LarkReleaseConfig
import LarkAccountInterface
import LarkFoundation
import ThreadSafeDataStructure
import LarkFeatureGating

class PassportSwitch: PassportSwitchProtocol {

    // MARK: PassportSwitchProtocol
    func set(_ key: PassportFeature, _ value: Bool) {
        featureMap[key] = value
    }

    func value(_ key: PassportFeature) -> Bool {
        return featureMap[key] ?? true
    }
    var enableJoinMetting: Bool = !ReleaseConfig.isKA

    // MARK: Private
    static let shared = PassportSwitch()

    private let _featureMap: SafeDictionary<PassportFeature, Bool> = {
        let map: [PassportFeature: Bool] = [
            .joinMeeting: false, //!ReleaseConfig.isKA,
            .toBIdPLogin: true,
            .toCIdPLogin: true,
            .recoverAccount: true,
            .joinTeam: true,
            .securityPassword: true,
            .keepLoginOption: Utils.isiOSAppOnMacSystem,
            .encryptAuthData: Utils.isiOSAppOnMacSystem
        ]
        return map + .readWriteLock
    }()
    private var featureMap: [PassportFeature: Bool] {
        get { _featureMap.getImmutableCopy() }
        set { _featureMap.replaceInnerData(by: newValue) }
    }

    var enableUUIDAndNewStoreReset: Bool {
        return PassportStore.shared.enableUUIDAndNewStoreReset
    }

    var enableLazySetupEventRegister: Bool = PassportStore.shared.enableLazySetupEventRegister

    var disableSessionInvalidDialogDuringLaunch: Bool {
        return PassportStore.shared.configInfo?.config().getDisableSessionInvalidDialogDuringLaunch() ?? V3NormalConfig.defaultDisableSessionInvalidDialogDuringLaunch
    }

    private init() {
        ttEnvHeader = UserDefaults.standard.string(forKey: passportTTEnvHeaderKey)
    }

    static let defaultEnableLogInLogin: Bool = true
    static let defaultEnablePassportRustHttp: Bool = true
    static let defaultForceDisableLogRustHttp: Bool = false

    var enableLogInLogin = PassportSwitch.defaultEnableLogInLogin

    // debug开关
    let disablePassportRustHTTPKey: String = "disablePassportRustHTTPKey"
    let disablePassportAPINewModelKey: String = "disablePassportAPINewModelKey"
    let passportTTEnvHeaderKey: String = "passportTTEnvHeaderKey"
    let enablePassportNetworkDebugToast: String = "passportNetworkDebugToast"

    var enablePassportRustHTTP: Bool {
        return !UserDefaults.standard.bool(forKey: disablePassportRustHTTPKey) && PassportSwitch.defaultEnablePassportRustHttp
    }
    
    var disablePassportAPINewModel: Bool {
        return UserDefaults.standard.bool(forKey: disablePassportAPINewModelKey)
    }

    var forceDisableLogRustHTTP: Bool = PassportSwitch.defaultForceDisableLogRustHttp

    var logUseRustHttp: Bool {
        if self.forceDisableLogRustHTTP {
            return false
        }
        return enablePassportRustHTTP
    }

    var ttEnvHeader: String? {
        didSet {
            UserDefaults.standard.set(ttEnvHeader, forKey: passportTTEnvHeaderKey)
        }
    }
}
