//
//  SwitchUserSwitchIdentityTask.swift
//  LarkAccount
//
//  Created by bytedance on 2021/8/31.
//

import Foundation
import LarkContainer
import RxSwift
import LarkAccountInterface
import EENavigator
import LarkUIKit
import ECOProbeMeta

enum SUSwitchIdentityTaskFrom: String {
    case `default` = "default" //flow 开始执行前期的检查任务
    case crossEnv = "after_cross_env" //flow 开始执行配置的任务
}

class SwitchUserSwitchIdentityBaseTask: NewSwitchUserTask {

    @Provider private var switchUserAPI: SwitchUserAPI // user:checked (global-resolve)
    @Provider private var userManager: UserManager
    
    private let disposeBag = DisposeBag()

    var context: UniContextProtocol {
        passportContext
    }

    var taskFrom: SUSwitchIdentityTaskFrom {
        .default
    }
    
    override func run() {
        logger.info(SULogKey.switchCommon, body: "switch identity task run")
        
        guard let credentialID = switchContext.switchUserInfo?.user.credentialID ?? switchContext.credentialId else {
            logger.info(SULogKey.switchCommon, body: "switch identity task fail with no credentialID")
            failCallback(AccountError.notFoundTargetUser)
            return
        }

        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.switchIdentityStart,
                                      categoryValueMap: ["request_type": taskFrom.rawValue],
                                      timerStart: .switchIdentity, context: monitorContext)

        let switchType = passportContext.switchType
        logger.info(SULogKey.switchIdentityRequestStart, method: .local)
        switchUserAPI
            .switchIdentity(to: switchContext.switchUserID,
                            credentialID: credentialID,
                            sessionKey: switchContext.switchUserInfo?.suiteSessionKey, switchType: switchType)
            .timeout(.seconds(PassportStore.shared.configInfo?.config().getSwitchUserSwitchIdentityTimeout() ?? V3NormalConfig.minSwitchUserSwitchIdentityTimeout), scheduler: MainScheduler.instance)
            .subscribe { [weak self] resp in
                guard let self = self else { return }

                self.logger.info(SULogKey.switchIdentityRequestSucc, method: .local)

                if resp.stepData.nextStep == PassportStep.enterApp.rawValue {
                    do {
                        let data = try JSONSerialization.data(withJSONObject: resp.stepData.stepInfo, options: .prettyPrinted)
                        let enterAppInfo = try JSONDecoder().decode(V4EnterAppInfo.self, from: data)

                        //监控
                        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.switchIdentityResult,
                                                      categoryValueMap: ["request_type": self.taskFrom.rawValue],
                                                      timerStop: .switchIdentity, isSuccessResult: true, context: self.monitorContext)

                        self.handleEnterAppInfo(enterAppInfo)
                        self.logger.info(SULogKey.switchIdentityEnterApp)
                    } catch {
                        self.logger.error(SULogKey.switchIdentityEnterApp, body: "switch identity task fail with data transform", error: error)
                        //监控
                        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.switchIdentityResult,
                                                      categoryValueMap: ["request_type": self.taskFrom.rawValue],
                                                      timerStop: .switchIdentity, isFailResult: true, context: self.monitorContext,
                                                      error: AccountError.dataParseError)

                        self.failCallback(AccountError.dataParseError)
                    }
                }else {

                    //监控
                    SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.switchIdentityResult, categoryValueMap: ["request_type": self.taskFrom.rawValue],
                                                  timerStop: .switchIdentity, isSuccessResult: true, context: self.monitorContext)

                    self.handleV3StepInfo(resp)
                    self.logger.error(SULogKey.switchIdentityOtherStep)
                }

            } onError: {[weak self] error in
                guard let self = self else { return }

                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.switchIdentityResult, categoryValueMap: ["request_type": self.taskFrom.rawValue],
                                              timerStop: .switchIdentity, isFailResult: true, context: self.monitorContext, error: error)
                
                if case RxError.timeout = error {
                    self.logger.error(SULogKey.switchCommon, body: "switch identity task request timeout")
                    self.failCallback(AccountError.switchUserTimeout)
                } else {
                    self.logger.error(SULogKey.switchCommon, body: "switch identity task fail", error: error)
                    self.failCallback(error)
                }
            }.disposed(by: disposeBag)
    }
    
    func handleEnterAppInfo(_ enterAppInfo: V4EnterAppInfo) {
        //session 等追加确认放在哪里
        if let remoteUser = enterAppInfo.userList.first,
           remoteUser.userID == switchContext.switchUserID {
            if let cachedUser = userManager.getUser(userID: remoteUser.userID) {
                // 只有在 session 内容或性质发生变化的时候才更新本地 User，否则服务端下发的 UserInfo 缺少信息，直接替换会有问题
                if (remoteUser.suiteSessionKey != cachedUser.suiteSessionKey) || (remoteUser.isAnonymous != cachedUser.isAnonymous) {
                    switchContext.switchUserInfo = remoteUser
                } else {
                    switchContext.switchUserInfo = V4UserInfo(user: remoteUser.user,
                                                              currentEnv: cachedUser.currentEnv,
                                                              logoutToken: cachedUser.logoutToken,
                                                              suiteSessionKey: cachedUser.suiteSessionKey,
                                                              suiteSessionKeyWithDomains: cachedUser.suiteSessionKeyWithDomains,
                                                              deviceLoginID: cachedUser.deviceLoginID,
                                                              isAnonymous: cachedUser.isAnonymous,
                                                              latestActiveTime: cachedUser.latestActiveTime,
                                                              isSessionFirstActive: remoteUser.isSessionFirstActive)//切换租户时需要使用服务端最新数据
                }
            } else {
                switchContext.switchUserInfo = remoteUser
            }
            logger.info(SULogKey.switchCommon, body: "switch identity task succ", method: .local)
            succCallback()
        } else {
            logger.error(SULogKey.switchCommon, body: "switch identity task fail with enterAppInfo has no userInfo")
            failCallback(AccountError.dataParseError)
        }
    }

    func handleV3StepInfo(_ stepInfo: V3.Step) {
        logger.error(SULogKey.switchCommon, body: "switch identity task failed with post v3 step method not override", additionalData: ["from": String(passportContext.from.rawValue)])
        failCallback(AccountError.switchUserVerifyCancel)
        assertionFailure("you should not call this func directly or subClass should override this function")
    }

    func onRollback(finished: @escaping (Result<Void, Error>) -> Void) {
        finished(.success(()))
    }

}
