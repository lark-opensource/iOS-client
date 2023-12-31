//
//  ContactsPermissionUGBannerHandler.swift
//  LarkContact
//
//  Created by mochangxing on 2021/3/19.
//

import UIKit
import Foundation
import Contacts
import LarkContainer
import LarkAccountInterface
import LarkFeatureGating
import LarkReleaseConfig
import LarkStorage
import UGBanner
import LarkSetting
import LarkSensitivityControl

final class ContactsPermissionUGBannerHandler: BannerHandler, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    public static let bannerName = "ContactsPermission"
    var requestAccessCallback: (() -> Void)?

    @KVConfig(
        key: KVKeys.Contact.permissionAlreadyClosedFlag,
        store: KVStores.udkv(space: .global, domain: contactDomain)
    )
    private var permissionAlreadyClosedFlag: Bool

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    // 处理Banner关闭事件
    func handleBannerClosed(bannerView: UIView) -> Bool {
        permissionAlreadyClosedFlag = true
        return false
    }

    // 处理Banner点击事件
    func handleBannerClick(bannerView: UIView, url: String) -> Bool {
        Tracer.trackAddressbookBannerClick()
        guard CNContactStore.authorizationStatus(for: CNEntityType.contacts) != .notDetermined else {
            do {
                let tk = Token("contacts_permission_banner")
                try ContactsEntry.requestAccess(forToken: tk, contactsStore: CNContactStore(), forEntityType: .contacts) { [weak self] (_, _) in
                    self?.requestAccessCallback?()
                }
            } catch {
                ContactLogger.shared.error(module: .action, event: "\(Self.self) no request contact token: \(error.localizedDescription)")
            }
            return true
        }
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
        }
        return true
    }

    func addressbookAuth() -> Bool {
        let bannerSwitchOn = userResolver.fg.staticFeatureGatingValue(with: .enableAddFromMobileContact)
        guard bannerSwitchOn else {
            // FG关闭，不展示权限引导banner
            return true
        }

        guard !permissionAlreadyClosedFlag else {
            // 关闭过返回true
            return true
        }
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        return authorizationStatus == .authorized
    }
}
