//
//  OPSDKRecoveryEntrance.swift
//  OPSDK
//
//  Created by liuyou on 2021/5/21.
//

import Foundation
import LarkOPInterface
import LKCommonsLogging
import OPFoundation

private let logger = Logger.oplog(OPSDKRecoveryEntrance.self, category: "OPSDKRecoverier")

@objcMembers
public final class OPSDKRecoveryEntrance: NSObject {

    /// 便捷入口，在有uniqueID，但拿不到containerContext时可以直接使用该入口接入错误恢复框架
    public static func handleError(
        uniqueID: OPAppUniqueID?,
        with error: OPError,
        recoveryScene: RecoveryScene,
        contextUpdater: ((RecoveryContext)->Void)? = nil) {
        guard let uniqueID = uniqueID else {
            logger.error("OPSDKRecoveryEntrance.handleError: uniqueID is nil")
            return
        }
        guard let container = OPApplicationService.current.getContainer(uniuqeID: uniqueID) else {
            logger.error("OPSDKRecoveryEntrance.handleError: can not get container from uniqueID \(uniqueID.fullString)")
            return
        }
        container.containerContext.handleError(with: error, scene: recoveryScene, contextUpdater: contextUpdater)
    }

}
