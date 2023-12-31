//
//  PipelineLongTimeNoLoginPushHandler.swift
//  LarkAccount
//
//  Created by au on 2022/12/22.
//

import EENavigator
import Foundation
import LarkAccountInterface
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import RustPB
import UniverseDesignDialog

/**
 https://bytedance.feishu.cn/wiki/wikcnecs1RpSPLEvAmRuTRf4xNh
 Rust Pipeline 14 天未激活，重新登录
 */
class PipelineLongTimeNoLoginPushHandler: BaseRustPushHandler<RustPB.Basic_V1_PushUserLogout> {

    static let logger = Logger.log(PipelineLongTimeNoLoginPushHandler.self, category: "Passport.PipelineLongTimeNoLoginPushHandler")

    @Provider private var userSessionService: UserSessionService
    @Provider private var switchUserService: NewSwitchUserService
    @Provider private var logoutService: LogoutService
    @Provider private var userManager: UserManager

    override func doProcessing(message: Basic_V1_PushUserLogout) {
        Self.logger.info("n_action_rust_long_time_no_login_handler")
        guard let foregroundUser = userManager.foregroundUser else { // user:current
            return
        }

        userSessionService.validateUserSessionOnline(foregroundUser) { online in // user:current
            if online {
                // 弹窗确认，自己切换自己
                guard let from = PassportNavigator.topMostVC else { return }
                Self.logger.info("n_action_rust_long_time_no_login_switch_self")

                let dialog = UDDialog()
                dialog.setContent(text: I18N.Lark_Passport_LoginSession_InactiveForLongPopUp_Text)
                dialog.addPrimaryButton(text: I18N.Lark_Passport_LoginSession_InactiveForLongPopUp_RefreshButton) {
                    self.switchUserService.switchWithoutServerInteraction(userInfo: foregroundUser, complete: { [weak self] complete in // user:current
                        Self.logger.info("n_action_rust_long_time_no_login_switch_finish")
                        guard let self = self else { return }
                        if !complete {
                            self.logoutForegroundUser()
                        }
                    }, context: UniContextCreator.create(.rustLongTimeNoLogin))
                }
                Navigator.shared.present(dialog, from: from) // user:checked (navigator)
            } else {
                // session 失效流程
                Self.logger.info("n_action_rust_long_time_no_login_session_invalid")
                self.userSessionService.start(reason: .rust)
            }
        }
    }

    private func logoutForegroundUser() {
        let config: LogoutConf
        if userManager.getActiveUserList().count > 1 {
            config = LogoutConf(forceLogout: true, destination: .switchUser, type: .foreground)
        } else {
            config = LogoutConf(forceLogout: true, destination: .login, type: .all)
        }

        logoutService.relogin(conf: config) { message in
            Self.logger.error("n_action_rust_long_time_no_login", body: "logout error: \(message)")
        } onSuccess: { [weak self] _ in
            Self.logger.info("n_action_rust_long_time_no_login", body: "unregister logout succ", method: .local)
            guard let self = self else { return }
            if self.userManager.getActiveUserList().count > 0 {
                self.switchUserService.autoSwitch(complete: { result in
                    Self.logger.info("n_action_rust_long_time_no_login", body: "switch result: \(result)")
                }, context: UniContextCreator.create(.rustLongTimeNoLogin))
            }
        } onInterrupt: {
            Self.logger.error("n_action_rust_long_time_no_login", body: "logout interruptted")
        }
    }
}

class UploadLogProgressPushHandler: BaseRustPushHandler<RustPB.Tool_V1_PushPackAndUploadLogProgress> {

    override func doProcessing(message: Tool_V1_PushPackAndUploadLogProgress) {
        let value = message.percentageProgress
        FetchClientLogHelper.updateUploadProgress(value)
    }
}
