//
//  SwitchUserInterruptTask.swift
//  LarkAccount
//
//  Created by bytedance on 2021/8/31.
//

import Foundation
import LarkContainer
import RxSwift
import LarkAccountInterface

class SwitchUserInterruptTask: SwitchUserPreTask {
    
    @Provider private var loginService: V3LoginService
    
    private let disposeBag = DisposeBag()
    
    override func run() {
        logger.info(SULogKey.switchCommon, body: "Interrupt task run", method: .local)

        // 被动切换租户时忽略中断信号
        // 后期应该推动业务方：
        // 只在中断中让用户进行确认，监听用户 offline 来做真正的清理工作
        // 或者由 passport 提供强制执行 interruptOperation 的时机
        if passportContext.switchType == .passive {
            logger.info(SULogKey.switchCommon, body: "Interrupt task skipped for passive switch")
            succCallback()
            return
        }

        if loginService.interruptOperations.isEmpty {
            logger.info(SULogKey.switchCommon, body: "Interrupt task succ with no interruptSignals")
            succCallback()
            return
        }

        if PassportStore.shared.configInfo?.config().getEnableNewSwitchInterruptProcess() ?? V3NormalConfig.defaultEnableNewSwitchInterruptProcess {
            logger.info(SULogKey.switchCommon, body: "new interrupt process", method: .local)
            newProcess()
        } else {
            logger.info(SULogKey.switchCommon, body: "legacy interrupt process")
            legacyProcess()
        }

    }

    /// 新流程变更点为中断信号改为一个一个按顺序处理；避免同时出现多个弹窗
    private func newProcess() {

        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.startInterrupt, context: monitorContext)

        Observable.from(loginService.interruptOperations)
        .concatMap { [weak self] interrupt -> Single<Bool> in
            self?.logger.info(SULogKey.switchCommon, body: "Interrupt task interruptSignal", additionalData: [
                "signal": String(describing: interrupt)
            ])
            return interrupt.getInterruptObservable(type: .switchAccount)
        }.map { (allow) -> Bool in
            if allow == false {
                throw V3LoginError.userCanceled
            }
            return true
        }
        .observeOn(MainScheduler.instance).subscribe(onError: { [weak self] error in
            guard let self = self else { return }
            self.logger.info(SULogKey.switchCommon, body: "Interrupt task fail")
            //监控
            SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.interruptResult, isFailResult: true, context: self.monitorContext)

            self.failCallback(AccountError.switchUserInterrupted)
        }, onCompleted: { [weak self] in
            guard let self = self else { return }
            self.logger.info(SULogKey.switchCommon, body: "Interrupt task succ", method: .local)
            //监控
            SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.interruptResult, isSuccessResult: true, context: self.monitorContext)

            self.succCallback()
        }).disposed(by: disposeBag)
    }

    private func legacyProcess() {

        let interruptObservable = loginService.interruptOperations.map { (interrupt) -> Single<Bool> in
            return interrupt.getInterruptObservable(type: .switchAccount)
        }

        logger.info(SULogKey.switchCommon, body: "Interrupt task interruptSignals", additionalData: [
            "signals": String(describing: interruptObservable.map({ String(describing: $0) }))
        ])

        Single
            .zip(interruptObservable)
            .catchError({ [weak self] (error) -> Single<[Bool]> in
                self?.logger.error(SULogKey.switchCommon, body: "Interrupt task error", error: error)
                return Single.just([true])
            })
            .flatMap { (results) -> Single<Bool> in
                for result in results where result == false {
                    return Single.just(false)
                }
                return Single.just(true)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] isNeedSwitch in
                guard let self = self else { return }

                if isNeedSwitch {
                    self.logger.info(SULogKey.switchCommon, body: "Interrupt task succ", method: .local)
                    self.succCallback()
                } else {
                    self.logger.info(SULogKey.switchCommon, body: "Interrupt task fail")
                    self.failCallback(AccountError.switchUserInterrupted)
                }
            })
            .disposed(by: disposeBag)
    }
}
