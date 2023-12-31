//
//  EMAPreloadAPI.swift
//  EEMicroAppSDK
//
//  Created by laisanpin on 2022/8/22.
//

import Foundation
import LKCommonsLogging

fileprivate let logger = Logger.oplog("EMAPreloadAPI")

/// 预处理统一入口
@objcMembers
public final class EMAPreloadAPI: NSObject {
    /// 预处理拉取
    public static func preload(scene: EMAAppPreloadScene, appTypes: [NSNumber]) {
        appTypes.forEach {
            if let appType = OPAppType(rawValue: $0.uintValue),
               let preloader = EMAPackagePreloadFactory.createPackagePreload(scene: scene, appType: appType) {
                preloader.fetchPreUpdateSettings()
            } else {
                assert(false, "[EMAPreloadAPI] preloader is nil for appTye: \($0)")
                logger.error("[EMAPreloadAPI] preloader is nil for appTye: \($0)")
            }
        }
    }

    /// 接收到push后预处理
    public static func onReceivePreloadPush(scene: EMAAppPreloadScene,
                                            appTypes: [NSNumber],
                                            pushInfo: [String : Any]) {
        appTypes.forEach {
            if let appType = OPAppType(rawValue: $0.uintValue),
               let preloader = EMAPackagePreloadFactory.createPackagePreload(scene: scene, appType: appType) {
                preloader.pushPreUpdateSettings(pushInfo)
            } else {
                assert(false, "[EMAPreloadAPI] preloader is nil for appTye: \($0)")
                logger.error("[EMAPreloadAPI] preloader is nil for appTye: \($0)")
            }
        }
    }
}
