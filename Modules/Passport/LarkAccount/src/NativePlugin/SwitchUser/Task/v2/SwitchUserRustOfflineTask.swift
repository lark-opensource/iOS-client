//
//  SwitchUserRustOfflineTask.swift
//  LarkAccount
//
//  Created by bytedance on 2022/8/4.
//

import Foundation
import LarkContainer
import LarkAccountInterface
import RxSwift
import ECOProbeMeta

class SwitchUserRustOfflineTask: NewSwitchUserTask {


    @Provider private var rustDependency: PassportRustClientDependency // user:checked (global-resolve)

    @Provider private var deviceService: DeviceService

    @Provider private var envManager: EnvironmentInterface

    @Provider private var userManager: UserManager

    @Provider private var stateService: PassportStateService

    private let disposeBag = DisposeBag()

    override func run() {

        logger.info(SULogKey.switchCommon, body: "rust offline task run", method: .local)
        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustOfflineStart, categoryValueMap: ["request_type": "default"], timerStart: .rustOffline, context: monitorContext)

        // 仅在有前台用户时更新状态
        // 登出前台用户后自动切换时前台用户为空，不改变状态
        if let user = userManager.foregroundUser?.makeUser() { // user:current
            let newState = PassportState(user: user, loginState: .offline, action: .switch)
            stateService.updateState(newState: newState)
        }

        rustDependency.makeUserOffline { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(_):
                self.logger.info(SULogKey.switchCommon, body: "rust offline task succ", method: .local)
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustOfflineResult,
                                              categoryValueMap: ["request_type": "default"],
                                              timerStop: .rustOffline,
                                              isSuccessResult: true, context: self.monitorContext)

                self.succCallback()
            case .failure(let error):
                //日志and监控
                self.logger.error(SULogKey.switchCommon, body: "rust offline task fail", error: error)
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustOfflineResult,
                                              categoryValueMap: ["request_type": "default"],
                                              timerStop: .rustOffline,
                                              isFailResult: true, context: self.monitorContext, error: error)

                self.failCallback(AccountError.switchUserRustFailed(rawError: error))
            }
        }
    }

    func onRollback(finished: @escaping (Result<Void, Error>) -> Void) {

        var observables: [RxSwift.Observable<Bool>] = []

        let setEnvRequest = Observable<Bool>.create { (ob) -> Disposable in

            self.logger.info("n_action_switch_rust_rollback_set_env_start", body: "env \(self.envManager.env)")

            //监控
            SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustSetEnvStart, categoryValueMap: ["request_type": "rollback"], timerStart: .rustSetEnv, context: self.monitorContext)

            self.rustDependency.updateRustEnv(self.envManager.env, brand: self.envManager.tenantBrand.rawValue) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(_):
                    self.logger.info("n_action_switch_rust_rollback_set_env_succ")
                    //监控
                    SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustSetEnvResult, categoryValueMap: ["request_type": "rollback"], timerStop: .rustSetEnv,
                                                  isSuccessResult: true,
                                                  context: self.monitorContext)

                    ob.onNext(true)
                    ob.onCompleted()
                case .failure(let error):
                    self.logger.error("n_action_switch_rust_rollback_set_env_fail", error: error)
                    //监控
                    SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustSetEnvResult, categoryValueMap: ["request_type": "rollback"], timerStop: .rustSetEnv,
                                                  isFailResult: true,
                                                  context: self.monitorContext, error: error)

                    ob.onError(error)
                }
            }
            return Disposables.create()
        }
        observables.append(setEnvRequest)

        let updateDeviceIdRequest = Observable<Bool>.create { (ob) -> Disposable in

            self.logger.info("n_action_switch_rust_rollback_set_deviceinfo_start", body: "did: \(self.deviceService.deviceId) iid: \(self.deviceService.installId)")

            //监控
            SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustSetDeviceInfoStart, categoryValueMap: ["request_type": "rollback"], timerStart: .rustSetDeviceInfo, context: self.monitorContext)

            self.rustDependency.updateDeviceInfo(did: self.deviceService.deviceId, iid: self.deviceService.installId) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success(_):
                    self.logger.info("n_action_switch_rust_rollback_set_deviceinfo_succ")
                    //监控
                    SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustSetDeviceInfoResult, categoryValueMap: ["request_type": "rollback"], timerStop: .rustSetDeviceInfo,
                                                  isSuccessResult: true,
                                                  context: self.monitorContext)

                    ob.onNext(true)
                    ob.onCompleted()
                case .failure(let error):
                    self.logger.error("n_action_switch_rust_rollback_set_deviceinfo_fail", error: error)
                    //监控
                    SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustSetDeviceInfoResult, categoryValueMap: ["request_type": "rollback"], timerStop: .rustSetDeviceInfo,
                                                  isFailResult: true,
                                                  context: self.monitorContext, error: error)

                    ob.onError(error)
                }
            }
            return Disposables.create()
        }
        observables.append(updateDeviceIdRequest)

        if let foregroundUser = UserManager.shared.foregroundUser { // user:current
            let onlineRequest = Observable<Bool>.create { (ob) -> Disposable in

                self.logger.info("n_action_switch_rust_rollback_online_start", body: "uid: \(foregroundUser.userID)") // user:current
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustOnlineStart, categoryValueMap: ["request_type": "rollback"], timerStart: .rustOnline, context: self.monitorContext)

                self.rustDependency.makeUserOnline(account: foregroundUser.makeAccount()) { [weak self] result in // user:current
                    guard let self = self else { return }

                    switch result {
                    case .success(_):
                        self.logger.info("n_action_switch_rust_rollback_online_succ")
                        //监控
                        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustOnlineResult, categoryValueMap: ["request_type": "rollback"], timerStop: .rustOnline,
                                                      isSuccessResult: true,
                                                      context: self.monitorContext)


                        ob.onNext(true)
                        ob.onCompleted()
                    case .failure(let error):
                        self.logger.error("n_action_switch_rust_rollback_online_fail", error: error)
                        //监控
                        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.rustOnlineResult, categoryValueMap: ["request_type": "rollback"], timerStop: .rustOnline,
                                                      isFailResult: true,
                                                      context: self.monitorContext, error: error)
                        ob.onError(error)
                    }
                }
                return Disposables.create()
            }
            observables.append(onlineRequest)
        }
        //顺序执行 rust set_env -> rust update_deviceInfo -> rust makeUserOnline
        Observable
            .concat(observables)
            .subscribe(onError: { error in
                finished(.failure(error))
            }, onCompleted: {
                finished(.success(()))
            }).disposed(by: disposeBag)
    }
}
