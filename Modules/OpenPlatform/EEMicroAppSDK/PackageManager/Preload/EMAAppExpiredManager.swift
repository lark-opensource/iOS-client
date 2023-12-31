//
//  EMAGadgetOverDueManager.swift
//  EEMicroAppSDK
//
//  Created by laisanpin on 2022/8/4.
//  预安装重构-应用过期

import Foundation
import LKCommonsLogging
import TTMicroApp

/// 小程序应用过期管理类
final class EMAGadgetExpiredManager: EMAPackagePreInfoProvider {
    static let logger = Logger.oplog(EMAGadgetExpiredManager.self, category: "EMAGadgetExpiredManager")

    private let workQueue = DispatchQueue(label: "com.bytedance.EMAMicroAppSDK.GadgetMetaExpired", qos: .utility, attributes: .init(rawValue: 0))

    public func fetchPreUpdateSettings() {
        workQueue.asyncAfter(deadline: .now() + .milliseconds(Int.DelayFetchInterval)) {
            guard let metaProvider = BDPModuleManager(of: .gadget)
                .resolveModule(with: MetaInfoModuleProtocol.self) as? MetaInfoModuleProtocol else {
                Self.logger.error("[EMAGadgetExpired] can not get meta provider")
                return
            }

            let expiredPreloadHandleInfos = MetaLocalAccessorBridge.getAllMetas(appType: .gadget).filter {
                //检查应用的过期enable状态
                guard BDPPreloadHelper.expiredEnable(appID: BDPSafeString($0.uniqueID.appID)) else {
                    return false
                }

                //筛选出过期的meta信息
                if let timestamp = metaProvider.getLocalMeta(with: MetaContext(uniqueID: $0.uniqueID, token: nil))?.getLastUpdateTimestamp() {
                    let expriedDuaration = BDPPreloadHelper.expiredDuration(appID: BDPSafeString($0.uniqueID.appID))
                    return self.isExpired(lastUpdateTime: timestamp.doubleValue / 1000, expiredTime: expriedDuaration)
                }

                // 没有时间戳的则认为没有过期
                return false
            }.map {
                BDPPreloadHandleInfo(uniqueID: $0.uniqueID,
                                     scene: BDPPreloadScene.MetaExpired,
                                     scheduleType: .toBeScheduled,
                                     injector: self)
            }

            Self.logger.info("[EMAGadgetExpired] exipred appIDs: \(expiredPreloadHandleInfos.map {BDPSafeString($0.uniqueID.appID)})")
            BDPPreloadHandlerManager.sharedInstance.handlePkgPreloadEvent(preloadInfoList: expiredPreloadHandleInfos)
        }
    }

    private func isExpired(lastUpdateTime: TimeInterval, expiredTime: TimeInterval) -> Bool {
        let now = Date().timeIntervalSince1970
        return (now - lastUpdateTime) > expiredTime
    }

    public func pushPreUpdateSettings(_ item: Any){}
}

extension EMAGadgetExpiredManager: BDPPreloadHandleInjector {
    public func onInjectInterceptor(scene: BDPPreloadScene,  handleInfo: BDPPreloadHandleInfo) -> [BDPPreHandleInterceptor]? {
        // 无网络情况下拦截
        let networkInterceptor = EMAInterceptorUtils.networkInterceptor()
        // 非wifi情况下拦截
        let cellularInterceptor = EMAInterceptorUtils.cellularInterceptor()

        return [networkInterceptor, cellularInterceptor]
    }
}

fileprivate extension String {
    static let Wifi = "wifi"
}

fileprivate extension Int {
    // 延迟获取过期延迟时间(毫秒)
    static let DelayFetchInterval = 5000
}
