//
//  SwitchUserFinalUpdateTask.swift
//  LarkAccount
//
//  Created by bytedance on 2021/9/4.
//

import Foundation
import BootManager
import LarkContainer
import LarkAccountInterface
import LarkEnv
import ECOProbeMeta

class SwitchUserFinalUpdateTask: NewSwitchUserTask {

    @Provider private var userManager: UserManager

    @Provider var stateService: PassportStateService

    @Provider private var launcher: Launcher
    
    @Provider private var passportCookieDependency: AccountDependency // user:checked (global-resolve)

    override func run() {
        logger.info(SULogKey.switchCommon, body: "final update task run", method: .local)

        guard let toUser = switchContext.switchUserInfo,
              let toUnit = toUser.user.unit else {
            logger.error(SULogKey.switchCommon, body: "final update task fail with no target userInfo")
            failCallback(AccountError.notFoundTargetUser)
            assertionFailure("something wrong, please contact passport")
            return
        }
        
        //session 必须是有效session
        guard toUser.isActive else {
            //上报埋点
            PassportMonitor.flush(EPMClientPassportMonitorUniversalDidCode.passport_switch_user_invalid_session,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: ["type": PassportStore.shared.universalDeviceServiceUpgraded ? 2 : 1],
                                  context: UniContextCreator.create(.switchUser))
            
            let error = V3LoginError.badResponse("invalid session")
            logger.error("n_action_switch_invalid_session", error: error)
            failCallback(error)
            assertionFailure("something wrong, please contact passport")
            return
        }

        // remove from hidden user
        userManager.removeHiddenUserByIDs([switchContext.switchUserID])
        //call delegates
        let account = toUser.makeAccount()
        launcher.execute(.beforeSwitchSetAccount, block: { $0.beforeSwitchSetAccount(account) })

        // update Env
        let newEnv = Env(unit: toUnit, geo: toUser.user.geo, type: EnvManager.env.type)
        let newBrand = toUser.user.tenant.brand.rawValue
        logger.info(SULogKey.switchCommon, body: "final update task update env \(newEnv), brand \(newBrand)", method: .local)
        EnvManager.switchEnv(newEnv, brand: newBrand)
        
        // 更新 cookie
        // https://bytedance.feishu.cn/docx/W3OZdeEHVoN6CGxavtBcsey5nze
        passportCookieDependency.clearCookie()
        if !passportCookieDependency.setupCookie(user: toUser.makeUser()) {
            failCallback(AccountError.switchUserSetupCookieError)
            return
        }

        // update foreground
        userManager.updateForegroundUser(toUser)

        // 尽可能早地更新状态，因为内部会初始化容器，避免有业务方监听 LauncherDelegate 直接/间接调用了容器态容器，而容器又没有初始化的情况
        let newState = PassportState(user: toUser.makeUser(), loginState: .online, action: .switch)
        stateService.updateState(newState: newState)

        // call delegates
        launcher.execute(.afterSwitchSetAccount, block: { $0.afterSwitchSetAccount(account) })
        //finish task
        logger.info(SULogKey.switchCommon, body: "final update task succ")
        succCallback()
    }

    func onRollback(finished: @escaping (Result<Void, Error>) -> Void) {
        logger.info(SULogKey.switchCommon, body: "final update task rollback with uid:  \(userManager.foregroundUser?.userID ?? "nil")") // user:current
        if let fromUser = userManager.foregroundUser { // user:current
            passportCookieDependency.setupCookie(user: fromUser.makeUser())
        }
        finished(.success(()))
    }
}
