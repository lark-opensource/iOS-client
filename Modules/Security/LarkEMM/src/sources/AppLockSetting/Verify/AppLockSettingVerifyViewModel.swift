//
//  AppLockSettingVerifyViewModel.swift
//  LarkMine
//
//  Created by thinkerlj on 2021/12/29.
//

import Foundation
import RxCocoa
import RxSwift
import EENavigator
import UniverseDesignToast
import LarkContainer
import Swinject
import LarkFeatureGating
import LarkFoundation
import LarkAccountInterface
import LarkSecurityComplianceInfra

enum AppLockSettingVerifyMode {
    case pinCode
    case touchID
    case faceID
}

final class AppLockSettingVerifyViewModel: UserResolverWrapper {

    @ScopedProvider private var userService: PassportUserService?

    let userResolver: UserResolver
    private var uid: String {
        userService?.user.userID ?? ""
    }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        let storage = SCKeyValue.globalMMKV()
        curEntryErrCount = storage.value(forKey: Self.currentEntryErrKey(uid)) ?? 0
    }

    var mode: AppLockSettingVerifyMode = .pinCode

    // Policy
    var maxEntryCount = 5
    var curEntryErrCount = 0 {
        didSet {
            let storage = SCKeyValue.globalMMKV()
            storage.set(curEntryErrCount, forKey: Self.currentEntryErrKey(uid))
            Logger.info("applock current input error count: \(curEntryErrCount)")
        }
    }

    var tmpPINCode = ""

    // modify flow
    var curModifyMode: AppLockSettingPINCodeModifyMode = .oldCodeVerify

    // privacy mode
    var privacyModeEnable: () -> Bool = {
        return false
    }

    lazy var title: String = {
        userService?.user.tenant.tenantName ?? ""
    }()

    weak var targetViewController: UIViewController?

    static func currentEntryErrKey(_ userID: String) -> String {
        let hashID = userID.md5()
        return "applock_current_entry_error_count_\(hashID)"
    }
}
