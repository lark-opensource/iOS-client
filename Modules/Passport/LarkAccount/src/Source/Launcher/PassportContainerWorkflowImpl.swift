//
//  PassportContainerWorkflowImpl.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/11/5.
//

import Foundation
import LarkAccountInterface
import LarkEnv
import LarkContainer

class PassportContainerWorkflowImpl: PassportContainerAfterRustOnlineWorkflow {

    //rust online成功后，passport的任务编排
    func runForgroundUserChangeWorkflow(action: PassportUserAction, foregroundUser: User, completion: @escaping (Result<Void, Error>) -> Void) {
        SuiteLoginUtil.runOnMain {
            switch action {
            case .initialized, .fastLogin, .settingsMultiUserUpdating:
                //无任务需要执行，直接返回
                completion(.success(()))
            case .login:
                self.doLoginWorkflow(foregroundUser: foregroundUser, completion: completion)
            case .logout:
                assertionFailure("something wrong, please contact passport")
                completion(.success(()))
            case .switch:
                self.doSwitchWorkflow(foregroundUser: foregroundUser, completion: completion)
            @unknown default:
                assertionFailure("something wrong, please contact passport")
                completion(.success(()))
            }
        }
    }

    func runlogoutForgroundUserWorkflow(completion: @escaping () -> Void) {
        SuiteLoginUtil.runOnMain {
            self.dologoutForgroundUserWorkflow(completion: completion)
        }
    }

    private func doLoginWorkflow(foregroundUser: User, completion: @escaping (Result<Void, Error>) -> Void) {

        @Provider var passportCookieDependency: AccountDependency

        guard let newForegroundUser = UserManager.shared.getUser(userID: foregroundUser.userID),
              let toUnit = newForegroundUser.user.unit else {
            //TODO: 上报监控
            assertionFailure("something wrong, please contact passport")
            completion(.failure(AccountError.notFoundTargetUser))
            return
        }

        // remove from hidden user
        UserManager.shared.removeHiddenUserByIDs([foregroundUser.userID])

        // update Env
        let newEnv = Env(unit: toUnit, geo: newForegroundUser.user.geo, type: EnvManager.env.type)
        let newBrand = newForegroundUser.user.tenant.brand.rawValue
        EnvManager.switchEnv(newEnv, brand: newBrand)

        // 种植cookie
        if !passportCookieDependency.setupCookie(user: newForegroundUser.makeUser()) {
            //TODO: 上报监控
        }

        // update foreground
        UserManager.shared.updateForegroundUser(newForegroundUser)

        //finish task
        completion(.success(()))
    }

    private func doSwitchWorkflow(foregroundUser: User, completion: @escaping (Result<Void, Error>) -> Void) {

        @Provider var launcher: Launcher

        @Provider var passportCookieDependency: AccountDependency

        guard let newForegroundUser = UserManager.shared.getUser(userID: foregroundUser.userID),
              let toUnit = newForegroundUser.user.unit else {
            //TODO: 上报监控
            assertionFailure("something wrong, please contact passport")
            completion(.failure(AccountError.notFoundTargetUser))
            return
        }

        if newForegroundUser.userID == UserManager.shared.foregroundUser?.userID &&
            newForegroundUser.suiteSessionKey == UserManager.shared.foregroundUser?.suiteSessionKey {
            //用户没有变更，举例场景：切换租户回滚
            completion(.success(()))
            return
        }

        // remove from hidden user
        UserManager.shared.removeHiddenUserByIDs([foregroundUser.userID])
        //call delegates
        let newForegroundAccount = newForegroundUser.makeAccount()
        launcher.execute(.beforeSwitchSetAccount, block: { $0.beforeSwitchSetAccount(newForegroundAccount) })

        // update Env
        let newEnv = Env(unit: toUnit, geo: newForegroundUser.user.geo, type: EnvManager.env.type)
        let newBrand = newForegroundUser.user.tenant.brand.rawValue
        EnvManager.switchEnv(newEnv, brand: newBrand)

        // 更新 cookie
        // https://bytedance.feishu.cn/docx/W3OZdeEHVoN6CGxavtBcsey5nze
        passportCookieDependency.clearCookie()
        if !passportCookieDependency.setupCookie(user: newForegroundUser.makeUser()) {
            //TODO: 上报监控

        }

        // update foreground
        UserManager.shared.updateForegroundUser(newForegroundUser)

        // call delegates
        launcher.execute(.afterSwitchSetAccount, block: { $0.afterSwitchSetAccount(newForegroundAccount) })
        //finish task
        completion(.success(()))
    }

    private func dologoutForgroundUserWorkflow(completion: @escaping () -> Void) {

        @Provider var launcher: Launcher

        guard let foregroundUser = UserManager.shared.foregroundUser else {
            //finish task
            completion()
            return
        }

        // call delegates
        let foregroundAccount = foregroundUser.makeAccount()
        launcher.execute(.beforeLogoutClearAccount, block: { $0.beforeLogoutClearAccount(foregroundAccount) })
        UserManager.shared.updateForegroundUser(nil)
        launcher.execute(.afterLogoutClearAccoount, block: { $0.afterLogoutClearAccoount(foregroundAccount) })

        //finish task
        completion()
    }
}
