//
//  FGControl.swift
//  LarkRustClientAssembly
//
//  Created by SolaWing on 2023/11/20.
//

import Foundation
import LarkAccountInterface
import LarkSetting
import EEAtomic
import LarkContainer
import OpenCombine

extension MultiUserActivitySwitch {
    /// FG规则:
    /// 1. 准用的FG关闭时，动态关闭。其他变化只影响本地存储, 但不改变内存的值.
    /// 2. 启用的FG当前用户开启时，启用功能. 所有上线用户关闭时，禁用功能.
    class Observer {
        static let shared = Observer()
        deinit {
            lock.deallocate()
        }
        init() {
            observeAllowFG()
        }
        /// 开始检查FG的变化并记录到UserDefaults中
        var enableMultipleUserInDisk: Bool {
            get { return UserDefaults.standard.bool(forKey: MultiUserActivitySwitch.enableMultipleUserKey) }
            set { UserDefaults.standard.set(newValue, forKey: MultiUserActivitySwitch.enableMultipleUserKey) }
        }
        private func _updateEnableMultipleUserInDisk() {
            lock.assertOwner()
            let value = allowMultiUserFG && enable()
            self.enableMultipleUserInDisk = value
            LarkContainerManager.logger.info("enableMultipleUser is \(value)")

            func enable() -> Bool {
                if enableMultipleUser.isEmpty { return enableMultipleUserInDisk }
                return enableMultipleUser.contains { $1 }
            }
        }
        var allowMultiUserFG: Bool = MultiUserActivitySwitch.enableMultipleUser {
            didSet {
                if oldValue == allowMultiUserFG { return }
                LarkContainerManager.logger.info("allow_multiuser change to \(allowMultiUserFG)")
                _updateEnableMultipleUserInDisk()
                if !allowMultiUserFG && MultiUserActivitySwitch.enableMultipleUserRealtime {
                    DispatchQueue.main.async {
                        guard MultiUserActivitySwitch.enableMultipleUserRealtime else { return }
                        MultiUserActivitySwitch.enableMultipleUserRealtime = false
                        LarkContainerManager.logger.info("enableMultipleUserRealtime change to false")
                        NotificationCenter.default.post(
                            name: MultiUserActivitySwitch.enableMultipleUserRealtimeChanged, object: nil)
                    }
                }
            }
        }
        var enableMultipleUser: [String: Bool] = [:]
        var enableMultipleUserObserver: [AnyCancellable] = []
        let lock = UnfairLockCell()

        private func observeAllowFG() {
            _ = FeatureGatingManager.realTimeManager.fgObservable.subscribe(onNext: {
                check()
            })
            check()
            func check() {
                lock.withLocking {
                    self.allowMultiUserFG = FeatureGatingManager.realTimeManager.featureGatingValue( // Global
                        with: .init(stringLiteral: "messenger.multiuser.allow_multiuser"))
                }
            }
        }

        /// 所有用户上线后再调用该方法
        /// 旧流程在旧前台用户上线后调用，新流程在所有用户流程结束后调用
        func observeEnableFG() {
            let userResolvers = UserStorageManager.shared.userStorages.map {
                Container.shared.getUserResolver(storage: $0)
            }
            let key = FeatureGatingManager.Key(stringLiteral: "messenger.multiuser.enable_multiuser")
            lock.lock(); defer { lock.unlock() }
            // 先observe，保证没有遗漏。变化会被lock挡住初始化后再计算
            enableMultipleUserObserver = userResolvers.map { resolver in
                resolver.fg.observe(key: key).sink { [self, userID = resolver.userID](value) in
                    lock.withLocking {
                        if enableMultipleUser[userID] == value { return }
                        enableMultipleUser[userID] = value
                        LarkContainerManager.logger.info("enable_multiuser \(userID) change to \(value)")
                        _updateEnableMultipleUserInDisk()
                    }
                }
            }
            enableMultipleUser = userResolvers.reduce(into: [:]) {
                $0[$1.userID] = $1.fg.dynamicFeatureGatingValue(with: key)
            }
            LarkContainerManager.logger.info("enable_multiuser is \(enableMultipleUser)")
            _updateEnableMultipleUserInDisk()
        }
    }
}
