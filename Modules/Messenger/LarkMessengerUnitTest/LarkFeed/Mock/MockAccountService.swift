//
//  MockAccountService.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/3.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkAccountInterface
import RxSwift
import BootManager
import LarkModel
import RustPB

// Account Mock
// 部分test case 依赖于userId等信息
class MockAccountService: AccountService {

    /// 模拟登陆，mock user信息
    static func login() {
        AccountServiceAdapter.setup(accountServiceImp: MockAccountService())
    }

    var currentAccountInfo: Account {
        let chatter = Chatter(id: "id",
                              name: "name",
                              localizedName: "localizedName",
                              enUsName: "enUsName",
                              namePinyin: "namePinyin",
                              alias: "alias",
                              type: .user,
                              avatarKey: "avatarKey",
                              avatar: ImageSet(),
                              updateTime: CACurrentMediaTime(),
                              creatorId: "creatorId",
                              isResigned: false,
                              isRegistered: true,
                              description: Basic_V1_Chatter.Description(),
                              withBotTag: "withBotTag",
                              canJoinGroup: true,
                              tenantId: "tenantId",
                              workStatus: Basic_V1_WorkStatus(),
                              profileEnabled: true,
                              chatExtra: nil,
                              accessInfo: Chatter.AccessInfo(),
                              email: nil,
                              doNotDisturbEndTime: 0,
                              openAppId: "openAppId",
                              acceptSmsPhoneUrgent: true)
        let tenant = TenantInfo(tenantId: "tenantId", tenantCode: "tenantCode", tenantTag: nil)
        let account = Account(
            chatter: chatter,
            accessToken: "accessToken",
            accessTokens: nil,
            logoutToken: nil,
            tenantInfo: tenant,
            userEnv: nil,
            userUnit: nil,
            securityConfig: nil,
            isIdp: nil,
            singleProductTypes: [],
            isFrozen: false,
            isActive: true,
            isGuest: false
        )
        return account
    }

    var currentAccountIsEmpty: Bool {
        false
    }

    var currentAccountObservable: Observable<Account> {
        .just(currentAccountInfo)
    }

    var currentUserTypeObservable: Observable<AccountUserType> {
        .just(.standard)
    }

    var accountChangedObservable: Observable<Account?> {
        .just(nil)
    }

    var accounts: [Account] {
        [currentAccountInfo]
    }

    var accountsObservable: Observable<[Account]> {
        .just([])
    }

    var pendingUser: PendingUser {
        PendingUser(userName: "",
                    userEnv: "",
                    userUnit: "",
                    tenantID: "",
                    tenantName: "",
                    tenantIconURL: "")
    }

    var pendingUsers: [PendingUser] {
        [pendingUser]
    }

    var pendingUsersObservable: Observable<[PendingUser]> {
        .just([pendingUser])
    }

    func relogin(conf: LogoutConf, onError: @escaping (String) -> Void, onSuccess: @escaping () -> Void, onInterrupt: @escaping () -> Void) {
    }

    func fetchAccounts() -> Observable<Void> {
        .just(())
    }

    func switchTo(chatterId: String) {
    }

    func switchTo(chatterId: String, complete: ((Bool) -> Void)?) {
    }

    func hasModifyPassword() -> Bool {
        true
    }

    func hasTwoFactorVerify() -> Bool {
        true
    }

    func hasAccountManage() -> Bool {
        true
    }

    func hasSecurityVerifyPwd() -> Bool {
        true
    }

    func hasDeviceManage() -> Bool {
        true
    }

    func fetchDoubleLoginVerify() -> Observable<Bool> {
        .just(true)
    }

    func setDoubleLoginVerify(isOpen: Bool) -> Observable<Void> {
        .just(())
    }

    func updatePassword(fromNavigation nav: UINavigationController, result: @escaping (UIViewController?) -> Void) {
    }

    func pushToTeamConversion(fromNavigation nav: UINavigationController, trackPath: String?) {
    }

    func joinTeam(withQRUrl url: String, fromVC: UIViewController, result: @escaping (Bool) -> Void) -> Bool {
        false
    }

    func upgradeTeamViewController(nav: UINavigationController, trackInfo: (path: String?, from: String?), handler: @escaping (Bool) -> Void, result: @escaping (UIViewController?) -> Void) {
    }

    func checkUnRegisterStatus(scope: UnregisterScope?) -> Observable<CheckUnRegisterStatusModel> {
        let statusModel = CheckUnRegisterStatusModel(enabled: true, notice: "", urlString: "")
        return .just(statusModel)
    }

    func unRegisteAccount(from: UINavigationController, success: @escaping () -> Void, error: @escaping (Error) -> Void) {
    }

    func startMigration(_ brand: String, _ unit: String) {
    }

    func getCurrentSecurityPwdStatus() -> Observable<(Bool, Bool)> {
        .just((true, true))
    }

    func getCurrentSecurityPwdRistStatus(callback: @escaping (Bool, Error?) -> Void) {
    }

    func getSecurityPwdViewControllerToPush(isSetPwd: Bool, createNewSuccess: @escaping () -> Void, callback: @escaping (UIViewController?) -> Void) {
    }

    func getSecurityStatus(appId: String, result: @escaping SecurityResult) {
    }

    func credentialList() -> UIViewController {
        UIViewController()
    }

    func getAccountPhoneNumbers() -> Observable<[PhoneNumber]> {
        .just([])
    }

    func open(data: [String: Any], success: @escaping () -> Void, failure: @escaping (Error) -> Void) {
    }

    func injectLogin(pattern: String?, regParams: [String: Any]?) {
    }

    func register(interruptOperation observable: InterruptOperation) {
    }

    func getTopCountryList() -> [String] {
        []
    }

    func getBlackCountryList() -> [String] {
        []
    }

    func launchGuideLogin(context: BootContext) -> Observable<Void> {
        .just(())
    }

    func createLoginNavigation(rootViewController: UIViewController) -> UINavigationController {
        UINavigationController()
    }
}
