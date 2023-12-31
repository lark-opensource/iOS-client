//
//  OPSilenceUpdateManager.swift
//  EEMicroAppSDK
//
//  Created by laisanpin on 2022/7/20.
//  产品话止血pull&push管理工具类

import Foundation
import TTMicroApp
import OPSDK
import LKCommonsLogging
import OPGadget

@objcMembers
public final class OPPackageSilenceUpdateManager: NSObject {
    static let logger = Logger.oplog(OPPackageSilenceUpdateProtocol.self, category: "OPPackageSilenceUpdateManager")
    /// 主动拉取止血配置
    public func fetchSilenceUpdateInfo() {
        guard OPPackageSilenceUpdateServer.shared.fetchUpdateInfoIsFinish else {
            return
        }

        BDPExecuteOnGlobalQueue {
            let gadgetAllUniqueIDs = MetaLocalAccessorBridge.getAllMetas(appType: .gadget).map({$0.uniqueID})
            let h5AllUniqueIDs = MetaLocalAccessorBridge.getAllMetas(appType: .webApp).map({$0.uniqueID})
            let allUniqueIDs = gadgetAllUniqueIDs + h5AllUniqueIDs
            Self.logger.info("[silenceUpdate] start fetchSilenceUpdateSettings \(allUniqueIDs.count)")
            OPPackageSilenceUpdateServer.shared.fetchSilenceUpdateSettings(allUniqueIDs, needSorted: true)
        }
    }

    /// 接收到push后拉取止血配置
    public func onReciveSilenceUpdate(_ pushAppID: String, extra: String) {
        guard OPPackageSilenceUpdateServer.shared.fetchUpdateInfoIsFinish else {
            return
        }

        BDPExecuteOnGlobalQueue {
            let gadgetAllUniqueIDs = MetaLocalAccessorBridge.getAllMetas(appType: .gadget).map({$0.uniqueID})
            let h5AllUniqueIDs = MetaLocalAccessorBridge.getAllMetas(appType: .webApp).map({$0.uniqueID})
            let allUniqueIDs = gadgetAllUniqueIDs + h5AllUniqueIDs
            var sortedUniqueIDs = OPPackageSilenceUpdateServer.shared.sortUniqueIDsByLaunchTime(allUniqueIDs)
            // OPPackageSilenceUpdateServer内部只关心appID. uniqueID其他数据暂时不使用.
            let pushUniqueID = OPAppUniqueID(appID: pushAppID, identifier: nil, versionType: .current, appType: .unknown)

            // 如果push过来的ID在缓存中,则放到首位. 如果不在则直接插入到第一个位置
            if sortedUniqueIDs.contains(where: { uniqueID in
                uniqueID.appID == pushAppID
            }) {
                sortedUniqueIDs = sortedUniqueIDs.sorted(by: { aUniqueID, _ in
                    aUniqueID.appID == pushAppID
                })
            } else {
                sortedUniqueIDs.insert(pushUniqueID, at: 0)
            }

            Self.logger.info("[silenceUpdate] start fetchSilenceUpdateSettings by push \(pushAppID) count: \(sortedUniqueIDs.count)")
            OPPackageSilenceUpdateServer.shared.fetchSilenceUpdateSettings(sortedUniqueIDs, needSorted: false)
        }
    }
}
