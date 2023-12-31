// 
// Created by duanxiaochen.7 on 2019/11/4.
// Affiliated with SpaceKit.
// 
// Description: OnboardingSynchronizer manages synchronization of states of onboarding tasks between local cache and remote storage.

import Foundation
import RxSwift
import SwiftyJSON
import SKFoundation
import SKInfra

final class OnboardingSynchronizer {

    static var shared = OnboardingSynchronizer()

    private var finishStatus: [OnboardingID: Bool] = [:]

    private lazy var dependency: SKCommonDependency! = DocsContainer.shared.resolve(SKCommonDependency.self)

    private var getRequestDisposable: Disposable? {
        willSet {
            getRequestDisposable?.dispose()
        }
    }

    private init() {
        syncFinishStatusWithRemote()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDidLogin),
                                               name: Notification.Name.Docs.userDidLogin,
                                               object: nil)
    }

    func isFinished(_ id: OnboardingID) -> Bool {
        return finishStatus[id] ?? false
    }

    func setBadgesFinished(ids: [String]) {
        pushFinishStatusToRemote(ids)
    }

    func setFinished(_ id: OnboardingID) {
        finishStatus[id] = true
        if CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.verifiesAllOnboardings) {
            DocsLogger.onboardingDebug("打开了统一调试引导开关，所以不将 \(id) 完成情况设置到 user defaults 和远端")
            return
        }
        DocsLogger.onboardingInfo("引导完成情况更新为：\(finishStatus)")
        CCMKeyValue.setSKOnboardingFinish(for: id)
        pushFinishStatusToRemote([id.rawValue])
    }

    func syncFinishStatusWithRemote() {
        DocsLogger.onboardingInfo("开始与远端同步引导完成情况，发起拉取请求")
        let lastSyncTime = Date()
        finishStatus = CCMKeyValue.getAllSKOnboardingStatuses()
        DocsLogger.onboardingInfo("从 UserDefaults 里面拿到的引导完成情况：\(finishStatus)")
        getRequestDisposable = dependency.getSKOnboarding()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (dict) in
                guard let self = self else { return }
                // Lark UG 后端接口返回 true 代表要显示引导，false 代表引导已被消费，和老的 ccm 后端接口逻辑恰好相反，
                // 所以拉到数据之后需要进行取反，与旧数据保持兼容，
                // Onboarding 模块的 cache 和 UserDefaults 的写值逻辑还是保持原样：true 代表显示过了，false 代表还未显示过
                var modifiedDict = dict
                for (key, value) in dict {
                    modifiedDict[key] = !value
                }
                DocsLogger.onboardingInfo("处理过后的后端返回数据：\(modifiedDict)")
                var updatingKeys: [String] = []
                for (id, isDone) in modifiedDict {
                    if let oid = OnboardingID(rawValue: id) {
                        if isDone == false && self.isFinished(oid) { // 对于离线完成的引导 case，在线之后批量同步到远端
                            updatingKeys.append(id)
                        }
                        let realStatus = isDone || self.isFinished(oid)
                        self.finishStatus[oid] = realStatus
                        if realStatus {
                            CCMKeyValue.setSKOnboardingFinish(for: id)
                        }
                    }
                }
                self.pushFinishStatusToRemote(updatingKeys)
                DocsLogger.onboardingInfo("引导完成情况更新为：\(self.finishStatus)")
                DocsLogger.onboardingDebug("Onboarding 与远端同步完成情况耗时 \(Date().timeIntervalSince(lastSyncTime)) 秒")
            })
    }

    private func pushFinishStatusToRemote(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        DocsLogger.onboardingInfo("将 \(ids) 的引导完成情况推送到远端")
        dependency.doneSKOnboarding(keys: ids)
    }

    @objc
    private func userDidLogin() {
        DocsLogger.onboardingInfo("用户重新登录完成，更新引导缓存")
        getRequestDisposable?.dispose()
        syncFinishStatusWithRemote()
    }

    func clear() {
        finishStatus = [:]
        DocsLogger.onboardingInfo("引导完成情况更新为：\(finishStatus)")
    }
}

extension CCMKeyValue {
    
    static func setSKOnboardingFinish(for oid: OnboardingID) {
        guard let uid = User.current.info?.userID else {
            DocsLogger.onboardingError("记录引导完成时拿不到 user id")
            return
        }
        DocsLogger.onboardingInfo("更新本地 UserDefaults 数据 \(uid)-\(oid.rawValue): true")
        CCMKeyValue.onboardingUserDefault(uid).set(true, forKey: "\(uid)-\(oid.rawValue)")
    }

    static func setSKOnboardingFinish(for id: String) {
        guard let uid = User.current.info?.userID else {
            DocsLogger.onboardingError("记录引导完成时拿不到 user id")
            return
        }
        DocsLogger.onboardingInfo("更新本地 UserDefaults 数据 \(uid)-\(id): true")
        CCMKeyValue.onboardingUserDefault(uid).set(true, forKey: "\(uid)-\(id)")
    }

    static func getSKOnboardingStatus(of oid: OnboardingID) -> Bool {
        guard let uid = User.current.info?.userID else {
            DocsLogger.onboardingError("记录引导完成时拿不到 user id")
            return false
        }
        return CCMKeyValue.onboardingUserDefault(uid).bool(forKey: "\(uid)-\(oid.rawValue)")
    }
// 预留接口，需要时取消注释
//    static func getSKOnboardingStatus(of id: String) -> Bool {
//        guard let uid = User.current.info?.userID else {
//            DocsLogger.onboardingError("记录引导完成时拿不到 user id")
//            return false
//        }
//        return CCMKeyValue.onboardingUserDefault(uid).bool(forKey: "\(uid)-\(id)")
//    }

    static func getAllSKOnboardingStatuses() -> [OnboardingID: Bool] {
        var statuses: [OnboardingID: Bool] = [:]
        for oid in OnboardingID.allCases {
            statuses[oid] = getSKOnboardingStatus(of: oid)
        }
        return statuses
    }
}
