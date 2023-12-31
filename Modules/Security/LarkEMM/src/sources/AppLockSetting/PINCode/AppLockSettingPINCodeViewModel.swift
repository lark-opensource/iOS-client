//
//  AppLockSettingPINCodeViewModel.swift
//  LarkMine
//
//  Created by thinkerlj on 2021/12/22.
//

import Foundation
import RxCocoa
import RxSwift
import EENavigator
import LarkContainer
import Swinject
import LarkFeatureGating
import LarkFoundation
import LarkAccountInterface

typealias AppLockSettingPINCodeCompletion = (_ mode: AppLockSettingPINCodeMode, _ isSuccess: Bool) -> Void

enum AppLockSettingPINCodeMode {
    case entry
    case modify
    case secondVerify
}

enum AppLockSettingPINCodeEntryMode {
    case input
    case verify
}

enum AppLockSettingPINCodeModifyMode {
    case oldCodeVerify
    case firstEntry
}

final class AppLockSettingPINCodeViewModel: UserResolverWrapper {
    private var dispostBag: DisposeBag = DisposeBag()
    @ScopedProvider private var appLockSettingService: AppLockSettingService?

    let userResolver: UserResolver
    var mode: AppLockSettingPINCodeMode
    var entryMode: AppLockSettingPINCodeEntryMode = .input
    var modifyMode: AppLockSettingPINCodeModifyMode = .oldCodeVerify
    var completion: AppLockSettingPINCodeCompletion?
    var performStatus = false

    // Policy
    let maxEntryCount = 3
    var curEntryCount = 0
    var isModifyLimitValid = false // 是否限制修改密码，默认为允许修改
    var tmpPINCode = ""
    var isSecurePINCodeEntry = true

    var title = ""
    var info = ""

    init(resolver: UserResolver,
         mode: AppLockSettingPINCodeMode,
         completion: AppLockSettingPINCodeCompletion?) {
        self.userResolver = resolver
        self.completion = completion
        self.mode = mode
    }

    func updateTitleInfo() {
        switch mode {
        case .entry:
            let tenantName = appLockSettingService?.formatTenantNameDesc ?? ""
            info = BundleI18n.AppLock.Lark_Screen_DigitalCodeTenantName(tenantName)
            switch entryMode {
            case .input:
                title = BundleI18n.AppLock.Lark_Screen_SetDigitalCode
            case .verify:
                title = BundleI18n.AppLock.Lark_Screen_EnterDigitalCodeAgain
            }
        case .modify:
            title = BundleI18n.AppLock.Lark_Screen_ModifyDigitalCode
            switch modifyMode {
            case .oldCodeVerify:
                info = BundleI18n.AppLock.Lark_Screen_EnterOldDigitalCode
            case .firstEntry:
                info = BundleI18n.AppLock.Lark_Screen_EnterNewDigitalCode
            }
        case .secondVerify:
            title = BundleI18n.AppLock.Lark_Screen_ModifyDigitalCode
            info = BundleI18n.AppLock.Lark_Screen_EnterDigitalCodeAgain
        }
    }
}
