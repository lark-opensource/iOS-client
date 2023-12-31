//
//  ExtensionAccountDelegate.swift
//  LarkExtensionAssembly
//
//  Created by Supeng on 2021/4/12.
//

import Foundation
import LKCommonsLogging
import LarkReleaseConfig
import LarkExtensionServices
import LarkFoundation
import LarkFeatureGating
import LarkContainer
import RxSwift
import LarkSetting
import LarkAccountInterface
import LarkUIKit

final class ExtensionAccountDelegate: PassportDelegate {

    static let logger = Logger.log(ExtensionAccountDelegate.self, category: "ExtensionAccountDelegate")

    public var name: String = "ExtensionAccountDelegate"

    @InjectedSafeLazy var deviceService: DeviceService

    func userDidOnline(state: PassportState) {
        guard let account = state.user else { return }
        ExtensionAccountDelegate.logger.info("Fast Login Account")
        setKeyValue(.currentAccountID, value: account.userID)
        setKeyValue(.currentAccountSession, value: account.sessionKey ?? "")
        setKeyValue(.currentUserAgent, value: LarkFoundation.Utils.userAgent)
        setKeyValue(.currentDeviceID, value: deviceService.deviceId)
        setKeyValue(.currentTenentID, value: account.tenant.tenantID)
        setKeyValue(.currentInstallID, value: deviceService.installId)
        setKeyValue(.currentUserUniqueID, value: encryptoId(account.userID))
        let appFullVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        setKeyValue(.currentAPPVersion, value: appFullVersion)

        ExtensionDomain.observeUserDomainUpdate(userID: account.userID)

        ExtensionAccountDelegate.logger.info("Set UserDefault")
    }

    func userDidOffline(state: PassportState) {
        ExtensionAccountDelegate.logger.info("After Logout")
        removeUserDefault()
    }

    func backgroundUserDidOnline(state: PassportState) {
        guard let account = state.user else { return }
        ExtensionDomain.observeUserDomainUpdate(userID: account.userID)
    }

    private func removeUserDefault() {
        SecureUserDefaults.shared.remove(with: .currentAccountID)
        SecureUserDefaults.shared.remove(with: .currentAccountSession)
        SecureUserDefaults.shared.remove(with: .currentUserAgent)
        SecureUserDefaults.shared.remove(with: .currentDeviceID)
        SecureUserDefaults.shared.remove(with: .currentTenentID)
        SecureUserDefaults.shared.remove(with: .currentInstallID)
        SecureUserDefaults.shared.remove(with: .currentUserUniqueID)
        SecureUserDefaults.shared.remove(with: .currentAPPVersion)

        ExtensionAccountDelegate.logger.info("Remove UserDefault")
    }

    private func setKeyValue(_ key: SecureUserDefaults.Key, value: String) {
        if value.isEmpty {
            ExtensionAccountDelegate.logger.error("Value is empty  Key: \(key.rawValue)")
        }
        try? SecureUserDefaults.shared.set(key: key, value: value)
    }

    private func encryptoId(_ id: String) -> String {
        if id.isEmpty {
            return ""
        }
        let encryptoId = prefixToken() + (id + suffixToken()).md5()
        return encryptoId.sha1()
    }

    private func prefixToken() -> String {
        let prefix = "ee".md5()
        if prefix.count > 6 {
            return prefix[0..<6]
        }
        return prefix
    }

    private func suffixToken() -> String {
        let prefix = "ee".md5()
        if prefix.count > 6 {
            return prefix[(prefix.count - 6)..<prefix.count]
        }
        return prefix
    }
}
