//
//  SwitchUserUpdateForegroundUserTask.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/11/1.
//

import Foundation
import LarkAccountInterface

class SwitchUserUpdateForegroundUserTask: NewSwitchUserTask {

    override func run() {

        guard let toUser = switchContext.switchUserInfo else {
            logger.error(SULogKey.switchCommon, body: "update foreground task fail with no target userInfo")
            failCallback(AccountError.notFoundTargetUser)
            assertionFailure("something wrong, please contact passport")
            return
        }

        logger.info(SULogKey.switchCommon, body: "SwitchUserUpdateForegroundUserTask run", method: .local)

        updateForegroundUserHasSideEffectTask(context: passportContext, action: .switch).runnable(toUser).execute { [weak self] _ in
            guard let self = self else { return }
            
            self.logger.info("SwitchUserUpdateForegroundUserTask succ")
            self.succCallback()
        } failureCallback: { [weak self] error in
            guard let self = self else { return }
            
            if case .switchUserRollbackError = error as? AccountError {
                self.failCallback(error)
            } else {
                self.logger.error("SwitchUserUpdateForegroundUserTask fail", error: error)
                self.failCallback(AccountError.switchUserRustFailed(rawError: error))
            }
        }
    }

    func onRollback(finished: @escaping (Result<Void, Error>) -> Void) {
        //不用处理回滚，
        finished(.success(()))
    }

}
