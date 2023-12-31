//
//  SwitchUserRustOnlineTask.swift
//  LarkAccount
//
//  Created by bytedance on 2022/8/4.
//

import Foundation
import LarkContainer
import LarkAccountInterface
import ECOProbeMeta

class SwitchUserRustOnlineTask: NewSwitchUserTask {

    @Provider private var rustDependency: PassportRustClientDependency // user:checked (global-resolve)

    override func run() {

        guard let toUser = switchContext.switchUserInfo else {
            logger.error(SULogKey.switchCommon, body: "rust online task fail with no target userInfo")
            failCallback(AccountError.notFoundTargetUser)
            assertionFailure("something wrong, please contact passport")
            return
        }

        logger.info(SULogKey.switchCommon, body: "rust online task run", method: .local)
        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustOnlineStart, categoryValueMap: ["request_type": "default"], timerStart: .rustOnline, context: monitorContext)


        let account = toUser.makeAccount()
        rustDependency.makeUserOnline(account: account) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(_):
                self.logger.info(SULogKey.switchCommon, body: "rust online task succ", method: .local)
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustOnlineResult, categoryValueMap: ["request_type": "default"], timerStop: .rustOnline, isSuccessResult: true, context: self.monitorContext)

                self.succCallback()
            case .failure(let error):
                //日志and监控
                self.logger.error(SULogKey.switchCommon, body: "rust online task fail", error: error)
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustOnlineResult, categoryValueMap: ["request_type": "default"], timerStop: .rustOnline, isFailResult: true, context: self.monitorContext)
                
                self.failCallback(AccountError.switchUserRustFailed(rawError: error))
            }
        }
    }

    func onRollback(finished: @escaping (Result<Void, Error>) -> Void) {

        logger.info(SULogKey.switchCommon, body: "n_action_switch_rust_rollback_offline_start")
        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustOfflineStart, categoryValueMap: ["request_type": "rollback"], timerStart: .rustOffline, context: monitorContext)


        rustDependency.makeUserOffline { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(_):
                self.logger.info("n_action_switch_rust_rollback_offline_succ")
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustOfflineResult, categoryValueMap: ["request_type": "rollback"], timerStop: .rustOffline, isSuccessResult: true, context: self.monitorContext)

                finished(.success(()))
            case .failure(let error):
                self.logger.error("n_action_switch_rust_rollback_offline_fail", error: error)
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustOfflineResult, categoryValueMap: ["request_type": "rollback"], timerStop: .rustOffline, isFailResult: true, context: self.monitorContext, error: error)

                finished(.failure(error))
            }
        }
    }
}
