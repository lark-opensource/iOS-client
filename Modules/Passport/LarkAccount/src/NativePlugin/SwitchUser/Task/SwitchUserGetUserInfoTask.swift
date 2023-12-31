//
//  SwitchUserGetUserInfoTask.swift
//  LarkAccount
//
//  Created by bytedance on 2021/8/31.
//

import Foundation
import RxSwift
import ECOProbeMeta
import LarkAccountInterface

class SwitchUserGetUserInfoTask: NewSwitchUserTask {

    private let disposeBag = DisposeBag()
    
    override func run() {

        logger.info(SULogKey.switchCommon, body: "get user info task run", method: .local)
        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.getUserInfoStart, timerStart: .getUserInfo, context: monitorContext)

        //如果 userInfo 已经有了, 直接成功
        if switchContext.switchUserInfo != nil {
            logger.info(SULogKey.switchCommon, body: "get user info task succ already had userInfo")
            //监控
            SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.getUserInfoResult, timerStop: .getUserInfo, isSuccessResult: true, context: monitorContext)

            succCallback()
            return
        }
        
        if let switchToUser = UserManager.shared.getUser(userID: switchContext.switchUserID) {
            logger.info(SULogKey.switchCommon, body: "get user info task succ from disk", method: .local)
            //监控
            SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.getUserInfoResult, timerStop: .getUserInfo, isSuccessResult: true, context: monitorContext)

            switchContext.switchUserInfo = switchToUser
            succCallback()
        } else if switchContext.credentialId != nil {
            logger.info(SULogKey.switchCommon, body: "get user info task succ already had credential id")
            //监控
            SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.getUserInfoResult, timerStop: .getUserInfo, isSuccessResult: true, context: monitorContext)

            succCallback()
        } else{
            logger.info(SULogKey.switchCommon, body: "get user info task request user list")

            UserManager.shared.fetchUserList().subscribe { [weak self] result in
                guard let self = self else { return }

                if let user = result.first(where: {$0.userID == self.switchContext.switchUserID}) {
                    self.logger.info(SULogKey.switchCommon, body: "get user info task succ from user list")
                    //监控
                    SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.getUserInfoResult, timerStop: .getUserInfo, isSuccessResult: true, context: self.monitorContext)

                    self.switchContext.switchUserInfo = user
                    self.succCallback()
                }else {
                    self.logger.error(SULogKey.switchCommon, body: "get user info task fail from user list")

                    //监控
                    SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.getUserInfoResult, timerStop: .getUserInfo, isFailResult: true, context: self.monitorContext, error: AccountError.notFoundTargetUser)

                    self.failCallback(AccountError.notFoundTargetUser)
                }
            } onError: {[weak self] error in
                guard let self = self else { return }
                self.logger.error(SULogKey.switchCommon, body: "get user info task fail from user list", error: error)
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.getUserInfoResult, timerStop: .getUserInfo, isFailResult: true, context: self.monitorContext, error: error)

                self.failCallback(error)
            }.disposed(by: disposeBag)
        }
    }

    func onRollback(finished: @escaping (Result<Void, Error>) -> Void) {
        finished(.success(()))
    }
}
