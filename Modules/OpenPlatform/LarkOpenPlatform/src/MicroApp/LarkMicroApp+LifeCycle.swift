//
//  LarkMicroApp+LifeCycle.swift
//  LarkMicroApp
//
//  Created by yinyuan on 2019/10/9.
//

import Foundation
import LarkSDKInterface
import LarkFeatureGating
import LKCommonsLogging
import RustPB
import LarkOPInterface
import EEMicroAppSDK
import LarkMicroApp

extension LarkMicroApp: MicroAppLifeCycleListener {
    public func onShow(context: EMALifeCycleContext) {
        let appid = context.uniqueID.appID
        if let auditService = resolver.resolve(OPAppAuditService.self) {
            auditService.auditEnterApp(appid)
        }
        LarkMicroApp.logger.info("LarkMicroApp LifeCycle onShow appid:\(appid) ")
        if let info = MicroAppInfoManager.shared.getAppInfo(appID: appid) {
            info.hide = false
            LarkMicroApp.logger.info("LarkMicroApp LifeCycle onShow did get info")
            if let feedAppID = info.feedAppID, let feedSeqID = info.feedSeqID {
                LarkMicroApp.logger.info("LarkMicroApp LifeCycle onShow feedAppID:\(feedAppID) feedSeqID:\(feedSeqID) feetype:\(info.feedType)")
                // 来自于 feed 的唤起需要消除 Badge
                let feedAPI = resolver.resolve(FeedAPI.self)
                    LarkMicroApp.logger.info("LarkMicroApp LifeCycle onShow clear badge feedAppID:\(feedAppID) feedSeqID:\(feedSeqID)")
                    feedAPI?.setAppNotificationRead(appID: feedAppID, seqID: feedSeqID)
                        .subscribe(onNext: { () in
                            info.feedAppID = nil
                            info.feedSeqID = nil
                        }).disposed(by: disposeBag)
            }
        }
    }

    public func onHide(context: EMALifeCycleContext) {
        let appid = context.uniqueID.appID
        LarkMicroApp.logger.info("LarkMicroApp LifeCycle onHide appid:\(appid) ")
        if let info = MicroAppInfoManager.shared.getAppInfo(appID: appid) {
            info.hide = true
        }
    }

    public func onCancel(context: EMALifeCycleContext) {
        let appid = context.uniqueID.appID
        LarkMicroApp.logger.info("LarkMicroApp LifeCycle onCancel appid:\(appid) ")
        MicroAppInfoManager.shared.removeAppInfo(appID: appid)
    }

    public func onDestroy(context: EMALifeCycleContext) {
        let appid = context.uniqueID.appID
        LarkMicroApp.logger.info("LarkMicroApp LifeCycle onDestroy appid:\(appid) ")
        MicroAppInfoManager.shared.removeAppInfo(appID: appid)
    }

}
