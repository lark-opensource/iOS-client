//
//  PasteboardServiceImp.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/7/6.
//

import Foundation
import LarkSecurityAudit
import LarkContainer
import LarkAccountInterface
import CommonCrypto
import EENavigator
import UIKit
import CryptoSwift
import AppContainer
import LarkSecurityComplianceInfra

public protocol PasteboardService {
    func checkProtectPermission() -> Bool
    func canHideMenuActions() -> Bool
    func hiddenItems() -> [String]
    func remainItems() -> [String]
    func currentEncryptUserId() -> String?
    func currentTenantName() -> String?
    func onWaterMarkViewCovered(_ window: UIWindow)

    func showDialog(_ point: String?)
    func dismissDialog()
    func monitorIfNeeded(action: String)
}

final class PasteboardServiceImp: PasteboardService, PermissionChangeAction, UserResolverWrapper {
    var identifier: String {
        return "LarkEMM.PasteboardServiceImp"
    }

    @ScopedProvider private var userService: PassportUserService?

    private var lastPasteProtectPermission: Bool?
    private var lastPasteProtectPermissionKey: String {
        let userId = currentEncryptUserId()
        return "PasteboardServiceImp.\(userId ?? "").lastPasteProtectPermission"
    }

    let userResolver: UserResolver
    let udkv: SCKeyValueStorage
    private let emmConfig: EMMConfig

    private var dialogReaction: PasteProtectReaction?

    private var pasteboardProtect: Bool?
    private var hasRegisterAction: Bool = false
    @ScopedProvider private var settings: Settings?
    @SafeWrapper var actions: Set<String> = []
    let timer: SCTimer?

    deinit {
        timer?.stopTimer()
        NotificationCenter.default.removeObserver(self)
    }
    init(resolver: UserResolver) throws {
        userResolver = resolver
        emmConfig = try resolver.resolve(assert: EMMConfig.self)
        udkv = SCKeyValue.userDefaultEncrypted(userId: resolver.userID, business: .pasteProtect)
        timer = SCTimer(config: TimerCongfig(timerInterval: 30 * 60, disableWhileBackground: true))
        timer?.handler = { [weak self] in
            guard let self else { return }
            self.reportMonitorIfNeeded()
        }
        timer?.startTimer()
    }

    func checkProtectPermission() -> Bool {
        // 是否集成了三方EMM能力
        if emmConfig.isPasteProtectDisabled {
            return false
        }

        // 当前是否有前台用户
        guard currentEncryptUserId() != nil else {
            return false
        }

        if let pasteboardProtect = pasteboardProtect {
            return pasteboardProtect
        }
        let currentPermission = getPasteboardProtectPermission()
        return currentPermission
    }

    func canHideMenuActions() -> Bool {
        guard checkProtectPermission() else {
            return false
        }
        guard (settings?.enableSecuritySettingsV2).isTrue else {
            if let disableMenuFunctionHidden = settings?.disablePasteProtectMenuOpt {
                return !disableMenuFunctionHidden
            } else {
                return true
            }
        }
        return !SCSetting.staticBool(scKey: .disablePasteProtectMenuOpt, userResolver: userResolver)
    }

    func hiddenItems() -> [String] {
        guard (settings?.enableSecuritySettingsV2).isTrue else {
            return settings?.pasteProtectHiddenItems ?? []
        }
        do {
            let service = try userResolver.resolve(assert: SCSettingService.self)
            let value: [String] = service.array(.pasteProtectHiddenItems)
            SCLogger.info("\(SCSettingKey.pasteProtectHiddenItems.rawValue) \(value)", tag: SCSetting.logTag)
            return value
        } catch {
            SCLogger.error("SCSettingsService resolve error \(error)")
            return []
        }
    }

    func remainItems() -> [String] {
        guard (settings?.enableSecuritySettingsV2).isTrue else {
            return settings?.pasteProtectRemainItems ?? []
        }
        do {
            let service = try userResolver.resolve(assert: SCSettingService.self)
            let value: [String] = service.array(.pasteProtectRemainItems)
            SCLogger.info("\(SCSettingKey.pasteProtectRemainItems.rawValue) \(value)", tag: SCSetting.logTag)
            return value
        } catch {
            SCLogger.error("SCSettingsService resolve error \(error)")
            return []
        }
    }

    func currentEncryptUserId() -> String? {
        let userId = self.userService?.user.userID
        return userId?.md5()
    }

    func currentTenantName() -> String? {
        return userService?.userTenant.tenantName
    }

    func onWaterMarkViewCovered(_ window: UIWindow) {
        let internalService = try? userResolver.resolve(assert: LarkEMMInternalService.self)
        internalService?.onWaterMarkViewCovered(window)
    }

    func showDialog(_ point: String?) {
        // 已经有弹框，不再弹起
        let isDislogShowing = dialogReaction?.isShowing ?? false
        guard !isDislogShowing else { return }
        dialogReaction = PasteProtectReaction(resolver: userResolver, pointId: point)
        dialogReaction?.show()
    }

    func dismissDialog() {
        dialogReaction?.dismiss()
        dialogReaction = nil
    }

    func onPermissionChange() {
        pasteboardProtect = nil
    }

    // 权限SDK获取最新开关值
    private func getPasteboardProtectPermission() -> Bool {
        let securityAudit = SecurityAudit()
        if !hasRegisterAction && SecurityAuditManager.shared.isStarted {
            securityAudit.registe(self)
            hasRegisterAction = true
        }
        let result: AuthResult = securityAudit.checkAuth(permType: .mobilePasteProtection, object: nil)
        if let userId = self.currentEncryptUserId(), result == .null || result == .allow {
            let pasteboardRemindKey = "lark.securityCompliance.\(userId).pasteboardRemindCopied"
            udkv.set(false, forKey: pasteboardRemindKey)
        }

        guard result != .error else {
            pasteboardProtect = nil
            return udkv.bool(forKey: lastPasteProtectPermissionKey)
        }
        let currentPermission = result == .deny
        // isStarted: 表示权限sdk是否初始化
        if SecurityAuditManager.shared.isStarted {
            pasteboardProtect = currentPermission
            cachePasteProtectPermission(currentPermission)
        }
        return currentPermission
    }

    private func cachePasteProtectPermission(_ currentPermission: Bool) {
        if currentPermission != lastPasteProtectPermission {
            lastPasteProtectPermission = currentPermission
            udkv.set(lastPasteProtectPermission, forKey: lastPasteProtectPermissionKey)
        }
    }
}

extension PasteboardServiceImp {
    func monitorIfNeeded(action: String) {
        guard let remainActions = SCPasteboard.general(SCPasteboard.defaultConfig()).canRemainActionsDescrption(),
                !remainActions.contains(action) else {
            return
        }
        actions.insert(action)
        if actions.count > 10 {
            reportMonitorIfNeeded()
        }
    }
    
    func reportMonitorIfNeeded() {
        guard !actions.isEmpty else { return }
        SCMonitor.info(singleEvent: .paste_protect, category: [
            "scene": "action_controlled",
            "actions": actions
        ])
        actions.removeAll()
    }
}
