//
//  OfflineLogoutHelper.swift
//  LarkAccount
//
//  Created by dengbo on 2021/7/6.
//

import Foundation
import RxSwift
import RxRelay
import LKCommonsLogging
import Reachability
import ECOProbeMeta

struct OfflineLogoutKey {
    static let logoutTokens = PassportStorageKey<[String]>(key: "logout_tokens")
}

class OfflineLogoutHelper {
    private static let logger = Logger.plog(OfflineLogoutHelper.self, category: "Suite.OfflineLogout")

    // tokens信号，初始化时从磁盘读取数据
    private let logoutTokensRelay = BehaviorRelay<[String]>(value: OfflineLogoutHelper.get(key: OfflineLogoutKey.logoutTokens) ?? [])
    private var observable: Observable<[String]>?
    private let context = UniContextCreator.create(.logoutOffline)
    private let disposeBag = DisposeBag()

    // 异步操作队列，执行磁盘读写任务
    private let queue = DispatchQueue(label: "Suite.OfflineLogout")

    // 网络可用性信号
    private let netReachable = {
        NotificationCenter.default.rx.notification(.reachabilityChanged).map({ _ in
            return (Reachability()?.connection ?? .none) != .none
        })
    }()

    // 定时器信号
    private let timer = {
        Observable<Int>.timer(.seconds(0), period: .seconds(Const.timerDelay), scheduler: MainScheduler.instance)
            .map { _ -> Void in }
    }()

    static let shared = OfflineLogoutHelper()

    private init() {

    }

    func start() {
        Self.logger.info("n_action_logout_offline_init")
        PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_offline_task_start, context: context)
        
        if let _ = observable { return }

        observable = Observable.combineLatest(
            netReachable,
            logoutTokensRelay.asObservable(),
            timer,
            resultSelector: { reachable, logoutTokens, _ in
                // 当有网，并且logoutTokens不为空时，需要执行离线登出逻辑
                if logoutTokens.count > 0 {
                    Self.logger.info("n_action_logout_offline_check", body: "reachable: \(reachable) token count: \(logoutTokens.count)")
                }
                return (reachable && !logoutTokens.isEmpty) ? logoutTokens : nil
            })
            .filter{ $0 != nil } // 因为上一步会返回nil，所以这里过滤掉nil
            // swiftlint:disable ForceUnwrapping
            .map { $0! } // nil已经被过滤掉了，强制解包
            // swiftlint:enable ForceUnwrapping
            .debounce(.seconds(3), scheduler: MainScheduler.instance)  // 避免重复发送请求
            .take(Const.retryCount) // 一次app生命周期内重试10次
            .flatMap { [weak self] (logoutTokens: [String]) -> Observable<[String]> in
                guard let self = self else { return .just([]) }
                let desensitizedTokens = logoutTokens.map { $0.desensitized() }
                Self.logger.info("n_action_logout_offline_request_start", body: "tokens: \(desensitizedTokens)")
                // 离线登出有token时打start点位
                ProbeDurationHelper.startDuration(ProbeDurationHelper.logoutOfflinePrimaryFlow)
                PassportMonitor.flush(PassportMonitorMetaLogout.startLogoutOffline,
                                      eventName: ProbeConst.monitorEventName,
                                      context: self.context)
                ProbeDurationHelper.startDuration(ProbeDurationHelper.logoutOfflineRequestFlow)
                PassportMonitor.flush(PassportMonitorMetaLogout.startLogoutOfflineRequest,
                                      eventName: ProbeConst.monitorEventName,
                                      context: self.context)
                PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_token_request_start, context: self.context)
                
                return NativeLogoutAPI()
                    .offlineLogout(logoutTokens: logoutTokens)
                    .do(onNext: { [weak self] _ in
                        Self.logger.info("n_action_logout_offline_request_succ", body: "tokens: \(desensitizedTokens)")
                        guard let self = self else { return }
                        self.monitorLogoutOfflineRequestResult(isSucceeded: true)
                        PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_token_request_succ, context: self.context)
                    },
                    onError: { [weak self] error in
                        Self.logger.error("n_action_logout_offline_request_fail", body: "tokens: \(desensitizedTokens)", error: error)
                        guard let self = self else { return }
                        self.monitorLogoutOfflineRequestResult(isSucceeded: false, error: error)
                        PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_token_request_fail, context: self.context, error: error)
                    })
                    .catchErrorJustReturn([])
            }

        observable?.subscribe(onNext: { [weak self] logoutTokens in
            // 上面请求报错后catchErrorJustReturn 返回了空数组，所以这里如果是空数据就表示失败了，不清空token
            guard let self = self else { return }
            guard !logoutTokens.isEmpty else {
                self.monitorLogoutOfflineEventResult(isSucceeded: false, errorMsg: "logout offline failed")
                PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_offline_task_end_fail, categoryValueMap: ["error_msg": "empty logoutTokens"], context: self.context)
                return
            }
            self.remove(logoutTokens: logoutTokens)
            
            Self.logger.info("n_action_logout_offline_succ")
            self.monitorLogoutOfflineEventResult(isSucceeded: true)
            PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_offline_task_end_succ, context: self.context)
        }).disposed(by: self.disposeBag)
    }

    func append(logoutTokens: [String]) {
        let desensitizedTokens = logoutTokens.map { $0.desensitized() }
        Self.logger.info("n_action_logout_offline_append", body: "tokens: \(desensitizedTokens)")
        
        queue.async {
            let diskTokens = Self.get(key: OfflineLogoutKey.logoutTokens) ?? []
            let mergeTokens = Array(Set(diskTokens + logoutTokens))
            self.logoutTokensRelay.accept(mergeTokens)
            Self.update(key: OfflineLogoutKey.logoutTokens, value: mergeTokens)
        }
    }

    private func remove(logoutTokens: [String]) {
        Self.logger.info("n_action_logout_offline_remove")
        
        queue.async {
            let diskTokens = Self.get(key: OfflineLogoutKey.logoutTokens) ?? []
            let finalTokens = diskTokens.filter({ !logoutTokens.contains($0) })
            self.logoutTokensRelay.accept(finalTokens)
            Self.update(key: OfflineLogoutKey.logoutTokens, value: finalTokens)
        }
    }

    // MARK: - Monitor

    // 离线登出主流程
    private func monitorLogoutOfflineEventResult(isSucceeded: Bool, errorMsg: String? = nil, error: Error? = nil) {
        let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.logoutOfflinePrimaryFlow)
        let monitor = PassportMonitor.monitor(PassportMonitorMetaLogout.logoutOfflineResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.duration: duration],
                                              context: context)

        if isSucceeded {
            monitor.setResultTypeSuccess().flush()
        } else {
            monitor.setResultTypeFail()
            let message: String? = (errorMsg != nil) ? errorMsg : "logout offline flow error \(error?.localizedDescription ?? "")"
            if let error = error {
                monitor.setPassportErrorParams(error: error)
            }
            monitor.setErrorMessage(message).flush()
        }
    }

    // 离线登出网络请求
    private func monitorLogoutOfflineRequestResult(isSucceeded: Bool, errorMsg: String? = nil, error: Error? = nil) {
        let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.logoutOfflineRequestFlow)
        let monitor = PassportMonitor.monitor(PassportMonitorMetaLogout.logoutOfflineRequestResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.duration: duration],
                                              context: context)

        if isSucceeded {
            monitor.setResultTypeSuccess().flush()
        } else {
            let message: String
            if let e = error, !e.localizedDescription.isEmpty {
                message = e.localizedDescription
            } else {
                message = errorMsg ?? "logout request flow error"
            }
            monitor.setResultTypeFail()
            if let error = error {
                _ = monitor.setPassportErrorParams(error: error)
            }
            monitor.setErrorMessage(message).flush()
        }
    }

}

extension OfflineLogoutHelper {
    fileprivate struct Const {
        // 这些是经验值，双端对齐
        static let timerDelay: Int = 30
        static let retryCount: Int = 10
    }
}

extension OfflineLogoutHelper {
    static func get<T>(key: PassportStorageKey<T>) -> T? where T: Codable {
        if passportStorageCipherMigration {
            return PassportStore.value(forKey: key)
        } else {
            return Isolator.layersGlobal(namespace: .passportGlobalIsolator).get(key: key)
        }
    }

    static func update<T>(key: PassportStorageKey<T>, value: T?) where T: Codable {
        if passportStorageCipherMigration {
            PassportStore.set(value, forKey: key)
        } else {
            _ = Isolator.layersGlobal(namespace: .passportGlobalIsolator).update(key: key, value: value)
        }
    }
}
