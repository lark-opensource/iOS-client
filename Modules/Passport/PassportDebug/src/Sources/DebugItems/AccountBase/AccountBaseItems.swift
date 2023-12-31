//
//  AccountBaseItems.swift
//  PassportDebug
//
//  Created by ByteDance on 2022/7/25.
//

import Foundation
import LarkDebugExtensionPoint
import LarkAccountInterface
import EENavigator
import RoundedHUD
import LarkEnv
import LarkContainer
import LarkAppLog
import UniverseDesignDialog
import LKCommonsLogging

class AccountBaseDebugItem: DebugCellItem {

    fileprivate var isLogin: Bool { return accountManager.isLogin }
    fileprivate var accountManager: AccountService

    var title: String { fatalError("Should be override") }
    var detail: String { fatalError("Should be override") }
    var canPerformAction: ((Selector) -> Bool)?
    var perfomAction: ((Selector) -> Void)?

    init(accountManager: AccountService) {
        self.accountManager = accountManager

        self.canPerformAction = { (action) in
            if #selector(UIResponderStandardEditActions.copy(_:)) == action {
                return true
            } else {
                return false
            }
        }

        self.perfomAction = { [weak self] (action) in
            if #selector(UIResponderStandardEditActions.copy(_:)) == action, let detail = self?.detail {
                UIPasteboard.general.string = detail
            }
        }
    }
}

class UserIDDebugItem: AccountBaseDebugItem {
    override var title: String { return "UserId" }

    override var detail: String {
        return isLogin ? accountManager.currentAccountInfo.userID : ""
    }
}

class TenantIDDebugItem: AccountBaseDebugItem {
    override var title: String { return "TenantId" }

    override var detail: String {
        return isLogin ? accountManager.currentAccountInfo.tenantInfo.tenantId : ""
    }
}

class DeviceIDItem: AccountBaseDebugItem {
    @Provider var deviceService: DeviceService

    override var title: String { return "DeviceID" }
    override var detail: String {
        return deviceService.deviceId
    }
}

class AppLogDeviceIDItem: AccountBaseDebugItem {
    override var title: String { return "AppLogDeviceID(埋点)" }
    override var detail: String {
        return LarkAppLog.shared.tracker.rangersDeviceID ?? ""
    }
}

class InstallIDItem: AccountBaseDebugItem {
    @Provider var deviceService: DeviceService

    override var title: String { return "InstallID" }
    override var detail: String { return deviceService.installId }
}
