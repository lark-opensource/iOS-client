//
//  LazyLoadFeatureGatingBarrier.swift
//  LarkSetting
//
//  Created by ByteDance on 2023/11/2.
//

import Foundation
import RxSwift
import EEAtomic
import LarkContainer
import RustPB
import LarkRustClient
import LKCommonsLogging
import LKCommonsTracker

class LazyLoadFeatureGatingUserBarrier {

    private let timeoutInterval: Int
    private let currentUserID: String
    private var barrierReleased = AtomicBool(false)
    private static let logger = Logger.log(LazyLoadFeatureGatingUserBarrier.self, category: "LazyLoadFeatureGatingUserBarrier")
    private static let timeoutIntervalMS = 100
    private let condition = NSCondition()
    private let startTime = Date().timeIntervalSince1970
    private let timeoutTime: TimeInterval
    private var disposeBag = DisposeBag()
    private let isOpen: Bool

    init(of userID: String, timeoutInterval: Int = timeoutIntervalMS) {
        self.currentUserID = userID
        self.timeoutInterval = timeoutInterval
        self.timeoutTime = startTime + Double(timeoutInterval)/1000.0
        let settingKey = UserSettingKey.make(userKeyLiteral: "lazy_load_fg_barrier_before_login")
        self.isOpen = (try? SettingStorage.setting(with: userID, type: Bool.self, key: settingKey.stringValue)) ?? false
    }

    func asyncWaitUntilPermissionOrTimeout() {
        if !isOpen { 
            Self.logger.info("asyncWaitUntilPermissionOrTimeout is not open")
            return
        }
        if let golbalService = Container.shared.resolve(GlobalRustService.self) {
            let permissionReceiver: Observable<RustPB.Settings_V1_PushLazyLoadFeatureGatingStarted> = golbalService.register(pushCmd: .pushLazyLoadFeatureGatingStarted)
            Self.logger.debug("asyncWaitUntilPermissionOrTimeout start register, \(currentUserID)")
            permissionReceiver
                .timeout(DispatchTimeInterval.milliseconds(timeoutInterval), scheduler: ConcurrentDispatchQueueScheduler(qos: .default))
                .flatMap { [weak self] (response) -> Observable<RustPB.Settings_V1_PushLazyLoadFeatureGatingStarted> in
                    guard let self = self else { return Observable.error(UserFeatureGatingError.BarrierError) }
                    if response.userID == self.currentUserID {
                        Self.logger.debug("asyncWaitUntilPermissionOrTimeout flatMap, \(self.currentUserID)")
                        return Observable.just(response)
                    } else {
                        Self.logger.debug("asyncWaitUntilPermissionOrTimeout not current user, \(self.currentUserID)")
                        return Observable.empty()
                    }
                }
                .take(1)
                .subscribe(
                    onNext: { [weak self] (response)  in
                        guard let self = self else { return }
                        if response.userID == self.currentUserID {
                            self.releaseBarrier()
                        }
                        let cost = (Date().timeIntervalSince1970 - startTime) * 1000
                        DispatchQueue.global(qos: .background).async {
                            Tracker.post(TeaEvent("lazy_load_fg_error_dev", params: ["cost_ms": cost]))
                        }
                    },
                    onError: { [weak self] (error) in
                        guard let self = self else { return }
                        Self.logger.warn("waitUntilPermissionOrTimeout error occurred: \(error)")
                        self.releaseBarrier()
                        let cost = (Date().timeIntervalSince1970 - startTime) * 1000
                        DispatchQueue.global(qos: .background).async {
                            Tracker.post(TeaEvent("lazy_load_fg_error_dev", params: ["cost_ms": cost, "error_msg": "barrier receive push timeout \(error)"]))
                        }
                    },
                    onCompleted: { [weak self] in
                        guard let self = self else { return }
                        Self.logger.debug("waitUntilPermissionOrTimeout onCompleted")
                        self.releaseBarrier()
                    }
                ).disposed(by: disposeBag)
        }else {
            releaseBarrier()
        }
    }

    func waitForBarrier(key: String) {
        if !isOpen { return }
        // 快速退出, 大多数情况不需要阻塞
        if self.barrierReleased.value {
            return
        }
        condition.lock()
        defer { condition.unlock() }
        // 双重检查
        if self.barrierReleased.value {
            Self.logger.debug("waitForBarrier not need wait, \(self.currentUserID)")
            return
        }
        
        Self.logger.debug("waitForBarrier start wait, \(self.currentUserID)")
        while !self.barrierReleased.value && Date().timeIntervalSince1970 < timeoutTime {
            if !condition.wait(until: Date(timeIntervalSince1970: timeoutTime)) {
                Self.logger.debug("waitForBarrier break wait, \(self.currentUserID)")
                let cost = (Date().timeIntervalSince1970 - startTime) * 1000
                DispatchQueue.global(qos: .background).async {
                    Tracker.post(
                        TeaEvent("lazy_load_fg_error_dev", params: ["fg_key": key, "cost_ms": cost, "error_msg": "wait barrier timeout"])
                    )
                }
                break
            }
        }
    }

    private func releaseBarrier() {
        if !isOpen { return }
        condition.lock()
        defer { condition.unlock() }
        self.barrierReleased.value = true
        condition.broadcast() // 唤醒所有等待的线程
        Self.logger.debug("asyncWaitUntilPermissionOrTimeout releaseBarrier, \(self.currentUserID)")
    }

}


