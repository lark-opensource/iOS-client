//
//  DLPManager.swift
//  SKCommon
//
//  Created by guoqp on 2022/7/5.
//

import Foundation
import YYCache
import LarkCache
import SKFoundation
import LarkStorage
import SpaceInterface
import UniverseDesignToast
import SKInfra

extension CCM {
    enum Dlp: Biz {
        static let parent: Biz.Type? = CCM.self
        static var path: String = "docsDlp"
    }
}

extension DlpManager {
    public static func status(with token: String, type: DocsType, action: DlpCheckAction) -> DlpCheckStatus {
        guard LKFeatureGating.docDlpEnable else {
            DocsLogger.error("dlp fg close")
            return .Safe
        }
        guard let id = User.current.basicInfo?.userID, !id.isEmpty else {
            spaceAssertionFailure()
            DocsLogger.error("DlpManager user id is nil")
            return .Safe
        }

        let manager = DocsContainer.shared.resolve(DlpManager.self)!
        manager.token = token
        let policy = manager.policyCache(with: token)
        let scs = manager.scsCache(with: token)
        let status = manager.combineWithExpiredCache(action: action, policy: policy, scs: scs) ?? .Safe

        PermissionStatistics.shared.reportDlpInterceptResultView(action: action, status: status)
        /// 选择性更新
        let needUpatePolicy = (policy == nil) || policy?.expired == true
        if needUpatePolicy {
            manager.updatePolicy(token: token, type: type.dlpType)
        }
        let needUpdateScs = (scs == nil) || scs?.expired == true
        if needUpdateScs {
            manager.updateScs(token: token, type: type.dlpType)
        }

        return status
    }

    public static func status(with token: String,
                              type: DocsType,
                              action: DlpCheckAction,
                              complete: @escaping ((DlpCheckStatus) -> Void)) {
        let trackComplete = { (status: DlpCheckStatus) in
            PermissionStatistics.shared.reportDlpInterceptResultView(action: action, status: status)
            complete(status)
        }
        guard LKFeatureGating.docDlpEnable else {
            DocsLogger.error("dlp fg close")
            trackComplete(.Safe)
            return
        }
        guard let id = User.current.basicInfo?.userID, !id.isEmpty else {
            spaceAssertionFailure()
            DocsLogger.error("DlpManager user id is nil")
            trackComplete(.Safe)
            return
        }

        let manager = DocsContainer.shared.resolve(DlpManager.self)!
        manager.token = token
        let policyCache = manager.policyCache(with: token)
        let scsCache = manager.scsCache(with: token)

        /// 无网情况下，有缓存就用
        if !DocsNetStateMonitor.shared.isReachable {
            let status = manager.combineWithExpiredCache(action: action, policy: policyCache, scs: scsCache) ?? .Safe
            trackComplete(status)
            return
        }
        manager.updateDlp(token: token, type: type.dlpType, policy: policyCache, scs: scsCache, action: action, complete: trackComplete)
    }

    static func dlpMaxCheckTime() -> Int {
        let manager = DocsContainer.shared.resolve(DlpManager.self)!
        return dlpMaxCheckTime(token: manager.token)
    }
    
    /// 后端DLP 缓存检测的最大耗时，单位是分钟
    static func dlpMaxCheckTime(token: String) -> Int {
        let manager = DocsContainer.shared.resolve(DlpManager.self)!
        guard let policyCache = manager.policyCache(with: token), policyCache.dlpMaxCheckTime > 0 else {
            return 15
        }
        return Int(policyCache.dlpMaxCheckTime / 60)
    }

    
    public static func updateCurrentToken(token: String) {
        let manager = DocsContainer.shared.resolve(DlpManager.self)!
        manager.token = token
    }
    
    public static func timerTime(token: String) -> TimeInterval {
        let manager = DocsContainer.shared.resolve(DlpManager.self)!
        guard let policyCache = manager.policyCache(with: token), policyCache.timeout > 0 else {
            return 10 * 60
        }
        return policyCache.timeout
    }
}

@available(*, deprecated, message: "Use PermissionSDK instead - PermissionSDK")
public final class DlpManager {
    public var token: String = ""
    private lazy var dlpCache: Cache = {
        let domain = Domain.biz.ccm.child("docsDlp")
        let cachePath: IsoPath = .in(space: .global, domain: domain).build(.document)
        let c: Cache = CacheManager.shared.cache(
            rootPath: cachePath,
            cleanIdentifier: "document/DocsSDK/docsDlp"
        )
        let countLimit: UInt = 200
        c.memoryCache?.countLimit = countLimit
        c.diskCache?.countLimit = countLimit
        return c
    }()

    private let permissonMgr = DocsContainer.shared.resolve(PermissionManager.self)!

    init() {}


    /// 合并dlp和scs 判断DlpCheckStatus， 缓存过期也有效
    private func combineWithExpiredCache(action: DlpCheckAction, policy: DlpPolicy?, scs: DlpScs?) -> DlpCheckStatus? {
        /// policy 不存在，直接返回nil
        guard let policy = policy else { return nil }
        /// policy未开启
        guard policy.hasOpen else { return .Safe }
        /// policy开启， 但scs不存在，直接返回nil
        guard let scs = scs else { return nil }
        return scs.status(with: action)
    }

    /// 合并dlp和scs 判断DlpCheckStatus， 缓存过期无效
    private func combineWithOutExpiredCache(action: DlpCheckAction, policy: DlpPolicy?, scs: DlpScs?) -> DlpCheckStatus? {
        /// policy 不存在 或 存在过期了，直接返回nil
        guard let policy = policy, !policy.expired else { return nil }
        /// policy未开启
        guard policy.hasOpen else { return .Safe }
        /// policy开启， 但scs不存在 或scs过期了，直接返回nil
        guard let scs = scs, !scs.expired else { return nil }
        return scs.status(with: action)
    }

    private func scsCache(with token: String) -> DlpScs? {
        guard let data: NSCoding = dlpCache.object(forKey: scsKey(token)) else {
            DocsLogger.info("scs cache is nil")
            return nil
        }
        return data as? DlpScs
    }

    private func policyCache(with token: String) -> DlpPolicy? {
        guard let data: NSCoding = dlpCache.object(forKey: policyKey(token)) else {
            DocsLogger.info("policy cache is nil")
            return nil
        }
        return data as? DlpPolicy
    }

    private func scsKey(_ token: String) -> String { token + "scs" }
    private func policyKey(_ token: String) -> String { token + "policy" }

    ///更新scs
    private func updateScs(token: String, type: String,
                           complete: ((DlpScs?) -> Void)? = nil) {
        permissonMgr.dlpscs(token: token, type: type) { [weak self] scs, error in
            guard let self = self else { return }
            let encryptToken = DocsTracker.encrypt(id: token)
            guard error == nil, let scs = scs else {
                DocsLogger.error("update dlp scs failed, token = \(encryptToken)")
                complete?(nil)
                return
            }
            DocsLogger.info("update dlp scs success, token = \(encryptToken)")
            self.dlpCache.set(object: scs, forKey: self.scsKey(token))
            complete?(scs)
        }
    }

    ///更新policy
    private func updatePolicy(token: String, type: String,
                              complete: ((DlpPolicy?) -> Void)? = nil) {
        permissonMgr.dlpPolicystatus(token: token, type: type) { [weak self] policy, error in
            guard let self = self else { return }
            let encryptToken = DocsTracker.encrypt(id: token)
            guard error == nil, let policy = policy else {
                DocsLogger.error("update dlp policy failed, token = \(encryptToken)")
                complete?(nil)
                return
            }
            DocsLogger.info("update dlp policy success, token = \(encryptToken)")
            self.dlpCache.set(object: policy, forKey: self.policyKey(token))
            complete?(policy)
        }
    }

    public static func prefetchDLP(token: String, type: DocsType, completion: @escaping () -> Void) {
        guard let manager = DocsContainer.shared.resolve(DlpManager.self) else {
            spaceAssertionFailure("DLP Manager not found!")
            completion()
            return
        }
        let requestGroup = DispatchGroup()
        requestGroup.enter()
        manager.updatePolicy(token: token, type: String(type.dlpType)) { _ in
            requestGroup.leave()
        }
        requestGroup.enter()
        manager.updateScs(token: token, type: String(type.dlpType)) { _ in
            requestGroup.leave()
        }

        requestGroup.notify(queue: .main) {
            completion()
        }
    }

    ///更新dlp和scs
    private func updateDlp(token: String, type: String, policy: DlpPolicy?, scs: DlpScs?, action: DlpCheckAction,
                           complete: ((DlpCheckStatus) -> Void)? = nil) {
        let requestGroup = DispatchGroup()
        var scsCache = scs
        var policyCache = policy

        requestGroup.enter()
        updatePolicy(token: token, type: type) { policy in
            if let policy = policy {
                policyCache = policy
            }
            requestGroup.leave()
        }

        requestGroup.enter()
        updateScs(token: token, type: type) { scs in
            if let scs = scs {
                scsCache = scs
            }
            requestGroup.leave()
        }

        requestGroup.notify(queue: DispatchQueue.main) { [weak self] in
            guard let self = self else { return }
            let status = self.combineWithExpiredCache(action: action, policy: policyCache, scs: scsCache) ?? .Safe
            complete?(status)
        }
    }
}

extension DlpManager {
    
    public static func showTipsIfUnSafe(on view: UIView, with info: DocsInfo, action: DlpCheckAction) -> Bool {
        let dlpStatus = Self.status(with: info.token, type: info.inherentType, action: action)
        guard dlpStatus == .Safe else {
            DocsLogger.info("dlp control, can not \(action.rawValue). dlp \(dlpStatus.rawValue)")
            let text = dlpStatus.text(action: action, isSameTenant: info.isSameTenantWithOwner)
            let type: DocsExtension<UDToast>.MsgType = dlpStatus == .Detcting ? .tips : .failure
            PermissionStatistics.shared.reportDlpSecurityInterceptToastView(action: action, status: dlpStatus, isSameTenant: info.isSameTenantWithOwner)
            UDToast.docs.showMessage(text, on: view, msgType: type)
            return true
        }
        return false
    }
    
}
