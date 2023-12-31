//
//  OpenPluginAppBadge.swift
//  OPPlugin
//
//  Created by yi on 2021/4/9.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import OPPluginBiz
import OPFoundation
import OPSDK
import ECOInfra
import LKCommonsLogging
import LarkSetting
import LarkContainer

final class OpenPluginAppBadge: OpenBasePlugin {
    
    lazy var apiUniteOpt: Bool = {
        userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.open.interface.api.unite.opt")
    }()
    
    @ScopedProvider var openApiService: LarkOpenAPIService?


    func onServerBadgePush(
        params: OpenAPIServerBadgePush,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            context.apiTrace.info("onServerBadgePush begin")
            guard EMAFeatureGating.boolValue(forKey: "gadget.open_app.badge") else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable).setMonitorMessage("not impl, fg not open").setOuterMessage("not impl")
            callback(.failure(error: error))
            return
            }
            let appId = params.appId ?? gadgetContext.uniqueID.appID
            let appIds = params.appIds ?? []
        
            if self.apiUniteOpt {
                guard let openApiService = self.openApiService else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unable).setMonitorMessage("not impl").setOuterMessage("not impl")
                    context.apiTrace.error("openApiService is nil")
                    callback(.failure(error: error))
                    return
                }
                openApiService.onServerBadgePush(appID: appId, subAppIDs: appIds) { (appBadge) in
                    self.fireServerBadgePush(appBadge: appBadge, context: context)
                }
                
            } else {
                guard let routeDelegate = EMAProtocolProvider.getEMADelegate() else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unable).setMonitorMessage("not impl").setOuterMessage("not impl")
                    callback(.failure(error: error))
                    return
                }
                routeDelegate.onServerBadgePush(appId, subAppIds: appIds) { (appBadge) in
                    self.fireServerBadgePush(appBadge: appBadge, context: context)
                }
            }
            callback(.success(data: nil))
        }
    
    private func fireServerBadgePush(appBadge: AppBadgeNode, context: OpenAPIContext) {
        let data: [String : Any] = ["appId": appBadge.appID,
                                    "updateTime": appBadge.updateTime,
                                    "badgeNum": appBadge.badgeNum,
                                    "version": appBadge.version,
                                    "feature": appBadge.feature.rawValue,
                                    "extra": appBadge.extra]
        do {
            let fireEvent = try OpenAPIFireEventParams(event: "serverBadgePushObserved",
                                                       sourceID: NSNotFound,
                                                       data: data,
                                                       preCheckType: .none,
                                                       sceneType: .normal)
            let result = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
            switch result {
            case let .failure(error: e):
                context.apiTrace.error("fire event serverBadgePushObserved fail \(e)")
            default:
                context.apiTrace.info("fire event serverBadgePushObserved success")
            }
        } catch {
            context.apiTrace.info("fire event serverBadgePushObserved params error \(error)")
        }

    }

    func offServerBadgePush(
        params: OpenAPIServerBadgePush,
        context:OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            context.apiTrace.info("offServerBadgePush begin")
            guard EMAFeatureGating.boolValue(forKey: "gadget.open_app.badge") else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unable).setMonitorMessage("not impl, fg not open").setOuterMessage("not impl")
                callback(.failure(error: error))
                return
            }
            let appId = params.appId ?? gadgetContext.uniqueID.appID
            let appIds = params.appIds ?? []
            
            if self.apiUniteOpt {
                guard let openApiService = self.openApiService else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unable).setMonitorMessage("not impl").setOuterMessage("not impl")
                    context.apiTrace.error("openApiService is nil")
                    callback(.failure(error: error))
                    return
                }
                openApiService.offServerBadgePush(appID: appId, subAppIDs: appIds)
                callback(.success(data: nil))
            } else {
                guard let routeDelegate = EMAProtocolProvider.getEMADelegate() else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unable).setMonitorMessage("not impl").setOuterMessage("not impl")
                    callback(.failure(error: error))
                    return
                }
                routeDelegate.offServerBadgePush(appId, subAppIds: appIds)
                callback(.success(data: nil))
            }
        }


    func updateBadge(params: OpenAPIUpdateBadgeParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard EMAFeatureGating.boolValue(forKey: "gadget.open_app.badge") else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable).setMonitorMessage("not impl, fg not open").setOuterMessage("not impl")
            callback(.failure(error: error))
            return
        }
        let uniqueID = gadgetContext.uniqueID
        var trackerParams = [AnyHashable: Any]()
        if uniqueID.appType == .gadget {
            trackerParams["MP"] = "application_type"
        } else if uniqueID.appType == .webApp {
            trackerParams["H5"] = "application_type"
        }
        if let common = BDPCommonManager.shared()?.getCommonWith(uniqueID), let model = OPUnsafeObject(common.model) {
            let appName = OPUnsafeObject(model.name) ?? ""
            trackerParams["appname"] = appName

        }
        trackerParams["badge_number"] = params.badgeNum
        trackerParams["app_id"] = uniqueID.appID
        BDPTracker.event("api_invoke_updateBadge", attributes: trackerParams, uniqueID: uniqueID)

        var extra = [AnyHashable: Any]()
        extra["badgeNum"] = params.badgeNum
        let scene = AppBadgeUpdateNodeScene.updateBadgeAPI
        extra["scene"] = scene
        context.apiTrace.info("updateBadge invoke app=\(uniqueID.appID), appType=\(uniqueID.appType) badgeNum=\(params.badgeNum)")

        let extraModel = UpdateBadgeRequestParameters(type: UpdateBadgeRequestParametersType.badgeNum)
        extraModel.scene = scene
        extraModel.badgeNum = params.badgeNum
        
        if self.apiUniteOpt {
            guard let openApiService = self.openApiService else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unable).setMonitorMessage("not impl").setOuterMessage("not impl")
                context.apiTrace.error("openApiService is nil")
                callback(.failure(error: error))
                return
            }
            openApiService.updateAppBadge(appID: uniqueID.appID, appType: self.appTypeToBadgeAppType(uniqueID.appType), extra: extraModel) { result, error in
                self.updateAppBadge(result: result, error: error, context: context, callback: callback, uniqueID: uniqueID)
            }
            let pullExtra = PullBadgeRequestParameters(scene: AppBadgePullNodeScene.rustNet)
            openApiService.pullAppBadge(appID: uniqueID.appID, appType: self.appTypeToBadgeAppType(uniqueID.appType), extra: pullExtra) { result, error in
                self.pullAppBadge(result: result, error: error, context: context, callback: callback, uniqueID: uniqueID)
            }
        } else {
            guard let routeDelegate = EMAProtocolProvider.getEMADelegate() else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unable).setMonitorMessage("not impl").setOuterMessage("not impl")
                callback(.failure(error: error))
                return
            }
            routeDelegate.updateAppBadge(uniqueID.appID, appType: self.appTypeToBadgeAppType(uniqueID.appType), extra: extraModel) { (result, error) in
                self.updateAppBadge(result: result, error: error, context: context, callback: callback, uniqueID: uniqueID)
            }
            let pullExtra = PullBadgeRequestParameters(scene: AppBadgePullNodeScene.rustNet)
            routeDelegate.pullAppBadge(uniqueID.appID, appType: self.appTypeToBadgeAppType(uniqueID.appType), extra: pullExtra) { (result, error) in
                self.pullAppBadge(result: result, error: error, context: context, callback: callback, uniqueID: uniqueID)
            }
        }
    }
    
    private func appTypeToBadgeAppType(_ appType: BDPType) -> AppBadgeAppType {
        let sourceAppType = appType
        var appType = AppBadgeAppType.unknown
        if (sourceAppType == BDPType.gadget) {
            appType = AppBadgeAppType.nativeApp
        } else if (sourceAppType == BDPType.webApp) {
            appType = AppBadgeAppType.webApp
        } else if (sourceAppType == BDPType.widget) {
            appType = AppBadgeAppType.nativeCard
        }
        return appType
    }

    
    private func pullAppBadge(result: PullAppBadgeNodeResponse?, error: Error?, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void, uniqueID: OPAppUniqueID) {
        if error != nil {
            context.apiTrace.error("updateBadge pullAppBadge error app=\(uniqueID.appID) errorMsg:\(error)")
            return
        }
        guard let result = result else {
            context.apiTrace.error("updateBadge pullAppBadge error app=\(uniqueID.appID) errorMsg:result illegal")
            return
        }
        let datas = result.noticeNodes
        let data = datas?.first
        if data == nil {
            context.apiTrace.error("updateBadge pullAppBadge error app=\(uniqueID.appID) errorMsg:rdata nil")
            return
        }
    }
    
    private func updateAppBadge(result: UpdateAppBadgeNodeResponse?, error: Error?, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void, uniqueID: OPAppUniqueID) {
        DispatchQueue.main.async {
            let responseMsg = result?.msg
            if let responseCode = result?.code {
                if responseCode == UpdateBadgeNodeActionCode.codeSuccess {
                    callback(.success(data: nil))
                } else {
                    context.apiTrace.error("updateBadge updateAppBadge error app=\(uniqueID.appID) errorCode:\(responseCode)")
                    switch responseCode {
                    case UpdateBadgeNodeActionCode.codeInvalidParams:
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam).setMonitorMessage("invalid parameter").setOuterMessage("invalid parameter")
                        callback(.failure(error: error))
                    case UpdateBadgeNodeActionCode.codeNonexistentNode:
                        let error = OpenAPIError(code: UpdateBadgeErrorCode.nonexistentBadge).setMonitorMessage("nonexistent badge").setOuterMessage("nonexistent badge")
                        callback(.failure(error: error))
                    default:
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError).setMonitorMessage("unknown error").setOuterMessage("unknown error")
                        callback(.failure(error: error))
                    }
                }
            } else {
                callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unknown)))
            }
        }
    }

    func reportBadge(params: OpenAPIUpdateBadgeParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIReportBadgeResult>) -> Void) {
        guard EMAFeatureGating.boolValue(forKey: "gadget.open_app.badge") else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable).setMonitorMessage("not impl, fg not open").setOuterMessage("not impl")
            callback(.failure(error: error))
            return
        }
        let uniqueID = gadgetContext.uniqueID

        context.apiTrace.info("reportBadge invoke app=\(uniqueID.appID), appType=\(uniqueID.appType) badgeNum=\(params.badgeNum)")
        let trace = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)
        let monitor = OPMonitor("op_app_badge_report_node").setUniqueID(uniqueID).tracing(trace).timing()
        let pullExtra = PullBadgeRequestParameters(scene: AppBadgePullNodeScene.rustNet)
        pullExtra.fromReportBadge = true
        guard let routeDelegate = EMAProtocolProvider.getEMADelegate() else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable).setMonitorMessage("not impl").setOuterMessage("not impl")
            callback(.failure(error: error))
            return
        }
        routeDelegate.pullAppBadge(uniqueID.appID, appType: self.appTypeToBadgeAppType(uniqueID.appType), extra: pullExtra) { (result, error) in
            DispatchQueue.main.async {
                if error != nil {
                    monitor.setResultTypeFail().setError(error).flush()
                    context.apiTrace.error("reportBadge pullAppBadge error app=\(uniqueID.appID) errorMsg:result illegal")
                    // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                    // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                    // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    callback(.failure(error: error))
                    return
                }
                guard let result = result else {
                    monitor.setResultTypeFail().setError(error).flush()
                    context.apiTrace.error("reportBadge pullAppBadge error app=\(uniqueID.appID) errorMsg:data nil")
                    // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                    // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                    // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    callback(.failure(error: error))

                    return
                }
                let datas = result.noticeNodes
                guard let data = datas?.first as? AppBadgeNode else {
                    monitor.setResultTypeFail().setError(error).flush()
                    context.apiTrace.error("reportBadge pullAppBadge error app=\(uniqueID.appID) errorMsg:data nil")
                    // 原逻辑为 serverBizError, CommoneErrorCode 不应当包含 serverBizError（因为每个 API 场景含义不同）。
                    // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                    // 三端一致会统一 CommoneCode，根据原 outerMessage 此处统一替换为 unknown，但仍然保持原 outerMessage 不变。
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    callback(.failure(error: error))
                    return
                }

                let responseBadgeNum = data.badgeNum
                let isMatched = params.badgeNum == responseBadgeNum
                monitor.setResultTypeSuccess().flush()
                callback(.success(data: OpenAPIReportBadgeResult(isMatched: isMatched)))
            }
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "updateBadge", pluginType: Self.self, paramsType: OpenAPIUpdateBadgeParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.updateBadge(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }

        registerInstanceAsyncHandlerGadget(for: "reportBadge", pluginType: Self.self, paramsType: OpenAPIUpdateBadgeParams.self, resultType: OpenAPIReportBadgeResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.reportBadge(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "onServerBadgePush", pluginType: Self.self, paramsType: OpenAPIServerBadgePush.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.onServerBadgePush(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }

        registerInstanceAsyncHandlerGadget(for: "offServerBadgePush", pluginType: Self.self, paramsType: OpenAPIServerBadgePush.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.offServerBadgePush(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }

    }
}
