//
//  LoginWrapper.swift
//  Minutes_Example
//
//  Created by Prontera on 2019/6/27.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import Foundation
import SuiteLogin
import RxSwift
import RustPB
import LarkRustClient
import WebKit
import RoundedHUD
import LarkAccountInterface
import LarkFoundation
import MinutesInterface
import MinutesFoundation
import Minutes
import SuiteAppConfig
import LarkLocalizations
import LarkModel
import RunloopTools
import ByteViewInterface
import LarkFeatureGating

typealias SetDeviceRequest = Device_V1_SetDeviceRequest
typealias UpdateDeviceRequest = Device_V1_UpdateDeviceRequest
typealias SetAccessTokenRequest = Tool_V1_SetAccessTokenRequest
typealias SwitchUserRequest = Tool_V1_SwitchUserRequest
typealias SwitchUserResponse = Tool_V1_SwitchUserResponse

public class LoginWrapper {
    private var lock = false
    private let disposebag = DisposeBag()
    let loginExtension: SuiteLoginExtension
    init(loginExtension: SuiteLoginExtension) {
        self.loginExtension = loginExtension
    }
}

extension LoginWrapper: LoginWrapperService {

    public func login(_ window: UIWindow?) {
        let suiteLogin = container.resolve(SuiteLogin.self)!

        let redirectToLogin: () -> Void = {
            window?.rootViewController = suiteLogin.login(fromGuide: false, callback: { [weak self] (userInfo: SuiteLoginUserInfo) in
                guard let self = self else { return }
                let deviceID = self.loginExtension.deviceService.deviceID
                self.loginSuccess(window: window, deviceId: deviceID, accountUserInfos: userInfo.users, currentUserIdx: userInfo.userIndex)
            })
        }

        suiteLogin.fastLogin { [weak self] (fastLoginResult) in
            guard let self = self else { return }
            switch fastLoginResult {
            case let .success(userInfo):
                let deviceID = self.loginExtension.deviceService.deviceID
                self.loginSuccess(window: window, deviceId: deviceID, accountUserInfos: userInfo.users, currentUserIdx: userInfo.userIndex)
            case let .failure(error):
                AppDelegate.logger.error("fast login error", error: error)
                redirectToLogin()
            }
        }
    }

    /// 登出
    public func relogin(cleanData: Bool) {
        if self.lock {
            return
        }
        let suiteLogin = container.resolve(SuiteLogin.self)!
        suiteLogin.logout(forceLogout: false, clearData: false, resetLoginOnError: LogoutConf.default.forceLogout) { [weak self] (suiteLogoutResult) in
            guard let self = self else { return }
            switch suiteLogoutResult {
            case .success:
                self.lock = false
                container.resetObjectScope(.user)
                container.resolve(RustService.self)!.unregisterPushHanlders()
                UIApplication.shared.applicationIconBadgeNumber = 0
                self.clearCookie(nil)
                self.login(UIApplication.shared.keyWindow)
            case .failure:
                self.lock = false
            }
        }
    }

    private func clearCookie(_ completion: (() -> Void)?) {
        let cstorage = HTTPCookieStorage.shared
        if let cookies = cstorage.cookies {
            for cookie in cookies {
                cstorage.deleteCookie(cookie)
            }
        }
    }

    private func loginSuccess(window: UIWindow?, deviceId: String, accountUserInfos: [AccountUserInfo], currentUserIdx: Int) {

        container.register(AccountDependency.self, factory: { _ in
            return AccountManager(accountUserInfos: accountUserInfos, currentUserIdx: currentUserIdx, deviceId: deviceId)
        }).inObjectScope(.user)
        container.register(AccountManagerService.self, factory: { _ in
            return AccountManager(accountUserInfos: accountUserInfos, currentUserIdx: currentUserIdx, deviceId: deviceId)
        }).inObjectScope(.user)
        container.resetObjectScope(.user)
        SideCarViewController.setStagingFeatureID()
        let rust = container.resolve(RustService.self)!
        var request = SetDeviceRequest()
        request.deviceID = deviceId
        request.installID = ""
        _ = rust.sendAsyncRequestBarrier(request).subscribe()

        let currentAccountUserInfo = accountUserInfos[currentUserIdx]
        var tokenRequest = SetAccessTokenRequest()
        tokenRequest.userID = currentAccountUserInfo.userID
        tokenRequest.accessToken = currentAccountUserInfo.session
        _ = rust.sendAsyncRequestBarrier(tokenRequest).subscribe()

        var updateDeviceRequest = UpdateDeviceRequest()
        updateDeviceRequest.name = UIDevice.current.name
        updateDeviceRequest.os = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        updateDeviceRequest.model = UIDevice.current.localizedModel
        _ = rust.sendAsyncRequestBarrier(updateDeviceRequest).subscribe()

        RunloopDispatcher.enable = true
        LarkFeatureGating.shared.clearFeatureBoolValues()
        LarkFeatureGating.shared.loadFeatureValues(with: currentAccountUserInfo.userID)
        LarkFeatureGating.shared.updateFeatureBoolValue(for: "byteview_mm_ios_recording", value: true)
        
        DispatchQueue.main.async {
            window?.rootViewController = container.resolve(UITabBarController.self)!
        }
    }

    public func switchToUser(_ user: AccountUserInfo) {
        let deviceID = container.resolve(AccountDependency.self)!.deviceId
        let accountManager = container.resolve(AccountManagerService.self)!
        var accountUserInfos = accountManager.accountUserInfos
        let userIdx = accountUserInfos.firstIndex { (account) -> Bool in
            account.userID == user.userID
        }
        guard let currentUserIdx = userIdx else { return }
        let currentAccount = container.resolve(AccountDependency.self)!
        let hud = RoundedHUD.showLoading()
        self.switchAccountUser(switchTo: user.userID, oldAccessToken: currentAccount.accessToken)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] session in
                hud.remove()
                guard let self = self else { return }
                accountUserInfos[currentUserIdx].session = session
                let suiteLogin = container.resolve(SuiteLogin.self)!
                suiteLogin.switchToUser(user)
                self.loginSuccess(window: UIWindow.lu.current, deviceId: deviceID, accountUserInfos: accountUserInfos, currentUserIdx: currentUserIdx)
                }, onDisposed: {
                    hud.remove()
            }).disposed(by: disposebag)
    }

    private func switchAccountUser(switchTo chatterId: String, oldAccessToken: String) -> Observable<String> {
        var request = SwitchUserRequest()
        request.userID = chatterId
        request.oldAccessToken = oldAccessToken
        var header = SwitchUserRequest.V3HeaderInfo()
        header.terminalType = .ios
        header.packageName = Utils.appName
        header.deviceName = UIDevice.current.name
        header.deviceOs = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
        header.deviceModel = UIDevice.current.lu.modelName()
        header.apiVersion = "3-8"
        request.headerInfo = header
        return container.resolve(RustService.self)!.sendAsyncRequest(request, transform: { (res: SwitchUserResponse) -> String in
            return res.accessToken
        }).subscribeOn(MainScheduler.instance)
    }
}
