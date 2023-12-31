//
//  BDPAppBadgeAPI.swift
//  EEMicroAppSDK
//
//  Created by yi on 2020/12/8.
//

import UIKit
import RustPB
import LarkRustClient
import RxSwift
import LKCommonsTracker
import LarkOPInterface
import LKCommonsLogging
import LarkOPInterface
import TTMicroApp

public protocol AppBadgeAPI {
    // 更新本地BadgeNode
    func updateAppBadge(_ appId: String, appType: AppBadgeAppType?, extra: UpdateBadgeRequestParameters?, completion: ((UpdateAppBadgeNodeResponse?, Error?) -> Void)?)
    // 更新本地BadgeNode
    func updateAppBadge(_ appId: String, appType: BDPType, badgeNum: Int, completion: ((_ result: UpdateAppBadgeNodeResponse?, _ error: Error?) -> Void)?)
    // 拉取客户端模块需要的BadgeNode
    func pullAppBadge(_ appId: String, appType: AppBadgeAppType?, extra: PullBadgeRequestParameters?, completion: ((_ result: PullAppBadgeNodeResponse?, _ error: Error?) -> Void)?)
}

class AppBadgeAPIImpl: AppBadgeAPI {
    static let monitor_op_app_badge_update_notice_node = "op_app_badge_update_notice_node"
    static let monitor_op_app_badge_pull_node = "op_app_badge_pull_node"

    private let client: RustService
    static let log = Logger.oplog(AppBadgeAPIImpl.self, category: "LarkMicroApp.BDPAppBadgeAPI")

    public init(client: RustService) {
        self.client = client
    }

    func appTypeToBadgeAppType(_ appType: BDPType) -> AppBadgeAppType {
        let sourceAppType = appType; // BDPWebAppEngine 对应BDPTypeWebApp
        var appType = AppBadgeAppType.unknown;
        if (sourceAppType == BDPType.gadget) {
            appType = AppBadgeAppType.nativeApp;
        } else if (sourceAppType == BDPType.webApp) {
            appType = AppBadgeAppType.webApp;
        } else if (sourceAppType == BDPType.widget) {
            appType = AppBadgeAppType.nativeCard;
        }
        return appType
    }

    public func updateAppBadge(_ appId: String, appType: AppBadgeAppType?, extra: UpdateBadgeRequestParameters?, completion: ((UpdateAppBadgeNodeResponse?, Error?) -> Void)?) {
        guard !(appId.isEmpty) else {
            return
        }
        let badgeAppType: AppBadgeAppType = appType ?? .unknown
        var request = RustPB.Openplatform_V1_UpdateOpenAppBadgeNodeRequest()
        request.appID = appId
        var brief = [String: Any]()
        brief["appId"] = appId
        if extra?.type == UpdateBadgeRequestParametersType.badgeNum {
            let badgeNum = extra?.badgeNum ?? -1
            if badgeAppType == AppBadgeAppType.nativeApp { // BDPType
                request.feature = .miniApp;
                brief["type"] = "mina"
            } else if badgeAppType == AppBadgeAppType.webApp {
                request.feature = .h5;
                brief["type"] = "h5"
            } else {
                return
            }
            if badgeNum >= Int32.min && badgeNum <= Int32.max {
                request.badgeNum = Int32(badgeNum)
            } else {
                request.badgeNum = -1
            }
            brief["num"] = badgeNum
        }
        if extra?.type == UpdateBadgeRequestParametersType.needShow {
            let needShow = extra?.needShow
            // needShow 不传feature，因为权限是应用级别的，一开h5，miniapp都开
            request.needShow = needShow ?? false
            brief["show"] = needShow
        }
        request.needTriggerPush = true
        AppBadgeAPIImpl.log.info("AppBadge: updateAppBadge invoke appId:\(appId) appType:\(badgeAppType.rawValue) badgeNum:\(String(describing: extra?.badgeNum)) needShow:\(String(describing: extra?.needShow))")

        var scene = -1
        scene = extra?.scene.rawValue ?? -1
        let briefsJson = [brief].op_toJSONString() ?? ""
        client.sendAsyncRequest(request)
            .subscribe(onNext: { (response: RustPB.Openplatform_V1_UpdateOpenAppBadgeNodeResponse) in
                if response.code == .codeSuccess {
                    OPMonitor(AppBadgeAPIImpl.monitor_op_app_badge_update_notice_node)
                        .addCategoryValue("scene", scene)
                        .addCategoryValue("badge_brief", briefsJson)
                        .setResultTypeSuccess()
                        .flush()

                } else {
                    OPMonitor(AppBadgeAPIImpl.monitor_op_app_badge_update_notice_node)
                        .addCategoryValue("scene", scene)
                        .addCategoryValue("badge_brief", briefsJson)
                        .setResultTypeFail()
                        .flush()
                }
                AppBadgeAPIImpl.log.info("AppBadge: updateAppBadge invoke completion appId:\(appId) appType:\(appType?.rawValue ?? 0) badgeNum:\(String(describing: extra?.badgeNum)) needShow:\(String(describing: extra?.needShow)) code:\(response.code)")
                var actionCode = UpdateBadgeNodeActionCode.unknownBadgeCode
                if (response.code == .unknownBadgeCode) {
                    actionCode = UpdateBadgeNodeActionCode.unknownBadgeCode
                } else if (response.code == .codeSuccess) {
                    actionCode = UpdateBadgeNodeActionCode.codeSuccess
                } else if (response.code == .codeInvalidParams) {
                    actionCode = UpdateBadgeNodeActionCode.codeInvalidParams
                } else if (response.code == .codeNonexistentNode) {
                    actionCode = UpdateBadgeNodeActionCode.codeNonexistentNode
                }
                let resultModel = UpdateAppBadgeNodeResponse(code: actionCode, msg: response.msg)
                completion?(resultModel, nil)
            }, onError: { (error) in
                AppBadgeAPIImpl.log.info("AppBadge: updateAppBadge invoke completion appId:\(appId) appType:\(badgeAppType.rawValue) badgeNum:\(String(describing: extra?.badgeNum)) needShow:\(String(describing: extra?.needShow)) errorMsg: \(error)")

                OPMonitor(AppBadgeAPIImpl.monitor_op_app_badge_update_notice_node)
                    .addCategoryValue("scene", scene)
                    .addCategoryValue("badge_brief", briefsJson)
                    .addCategoryValue("errorReason", error.localizedDescription)
                    .setResultTypeFail()
                    .flush()
                completion?(nil, error)
            }, onCompleted: {
            }, onDisposed: {
            })

    }

    public func updateAppBadge(_ appId: String, appType: BDPType, badgeNum: Int, completion: ((UpdateAppBadgeNodeResponse?, Error?) -> Void)?) {
        let extra = UpdateBadgeRequestParameters(type: UpdateBadgeRequestParametersType.badgeNum)
        extra.badgeNum = badgeNum
        updateAppBadge(appId, appType: self.appTypeToBadgeAppType(appType), extra: extra, completion: completion)
    }

    public func pullAppBadge(_ appId: String, appType: AppBadgeAppType?, extra: PullBadgeRequestParameters?, completion: ((_ result: PullAppBadgeNodeResponse?, _ error: Error?)->Void)?) {
        guard !(appId.isEmpty) else {
            return
        }
        let badgeAppType: AppBadgeAppType = appType ?? .unknown

        var request = RustPB.Openplatform_V1_PullOpenAppBadgeNodesRequest()
        request.isMobile = true
        var idFeature: Openplatform_V1_PullOpenAppBadgeNodesRequest.IdFeaturePair = RustPB.Openplatform_V1_PullOpenAppBadgeNodesRequest.IdFeaturePair()
        idFeature.appID = appId
        // 工作台的批量设置不传appType
        if badgeAppType == AppBadgeAppType.nativeApp {
            idFeature.feature = .miniApp;
        } else if badgeAppType == AppBadgeAppType.webApp {
            idFeature.feature = .h5;
        }

        request.idFeaturePairs = [idFeature]
        request.strategy = .net
        var scene = -1
        scene = extra?.scene.rawValue ?? -1
        var briefs = [Any]()
        var fromReportBadge = false
        fromReportBadge = extra?.fromReportBadge ?? false
        if !fromReportBadge { // 除reportBadge外都触发push
            request.needTriggerPush = true
        }
        AppBadgeAPIImpl.log.info("AppBadge: pullAppBadge invoke appId:\(appId) appType:\(appType?.rawValue ?? 0)")
        client.sendAsyncRequest(request)
            .subscribe(onNext: { (response: RustPB.Openplatform_V1_PullOpenAppBadgeNodesResponse) in
                var datas = [Any]()
                var dataModels = [AppBadgeNode]()
                for noticeNode in response.noticeNodes {

                    var feature = AppBadgeAppFeatureType.miniApp
                    if noticeNode.feature == .miniApp {
                        feature = AppBadgeAppFeatureType.miniApp
                    } else if noticeNode.feature == .h5 {
                        feature = AppBadgeAppFeatureType.h5
                    }
                    let badgeNum: Int = Int(noticeNode.badgeNum)
                    let dataModel = AppBadgeNode(feature: feature, appID: noticeNode.appID, needShow: noticeNode.needShow, updateTime: noticeNode.updateTime, badgeNum: badgeNum, extra: noticeNode.extra, version: noticeNode.version)
                    dataModels.append(dataModel)

                    var brief = [String: Any]()
                    brief["appId"] = appId
                    if badgeAppType == AppBadgeAppType.nativeApp {
                        brief["type"] = "mina"
                    } else if badgeAppType == AppBadgeAppType.webApp {
                        brief["type"] = "h5"
                    }
                    brief["show"] = noticeNode.needShow
                    brief["num"] = noticeNode.badgeNum
                    briefs.append(brief)
                }
                let briefsJson = briefs.op_toJSONString()
                OPMonitor(AppBadgeAPIImpl.monitor_op_app_badge_pull_node)
                    .addCategoryValue("scene", scene)
                    .addCategoryValue("badge_brief", briefsJson)
                    .setResultTypeSuccess()
                    .flush()
                AppBadgeAPIImpl.log.info("AppBadge: pullAppBadge invoke completion appId:\(appId) appType:\(appType?.rawValue ?? 0)")

                let resultModel = PullAppBadgeNodeResponse(noticeNodes: dataModels)
                completion?(resultModel, nil)
            }, onError: { (error) in

                var brief = [String: Any]()
                brief["appId"] = appId
                if badgeAppType == AppBadgeAppType.nativeApp {
                    brief["type"] = "mina"
                } else if badgeAppType == AppBadgeAppType.webApp {
                    brief["type"] = "h5"
                }
                let briefsJson = [brief].op_toJSONString()
                OPMonitor(AppBadgeAPIImpl.monitor_op_app_badge_pull_node)
                    .addCategoryValue("scene", scene)
                    .addCategoryValue("badge_brief", briefsJson)
                    .addCategoryValue("errorReason", error.localizedDescription)
                    .setResultTypeFail()
                    .flush()
                AppBadgeAPIImpl.log.info("AppBadge: pullAppBadge invoke completion appId:\(appId) appType:\(badgeAppType.rawValue) errorMsg: \(error)")
                completion?(nil,error)

            }, onCompleted: {
            }, onDisposed: {
            })
    }
}
