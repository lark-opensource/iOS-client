//
//  OpenPluginShareAppMessageDirectly.swift
//  OPPlugin
//
//  Created by bytedance on 2021/6/16.
//

import UIKit
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPFoundation
import OPPluginManagerAdapter
import TTMicroApp
import LarkContainer

final class OpenPluginShareAppMessageDirectly: OpenBasePlugin {
    func shareAppMessageDirectly(
        params: OpenPluginShareAppMessageDirectlyParams,
        context:OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginShareAppMessageDirectlyResult>) -> Void) {
        context.apiTrace.info("begin shareAppMessageDirectly api, path: \(params.path.toBase64())")
        let uniqueID = gadgetContext.uniqueID
        let trace = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)
        OPMonitor(kEventName_mp_share_start).setUniqueID(uniqueID).tracing(trace).flush()
        let monitor = OPMonitor(kEventName_mp_share_result).setUniqueID(uniqueID).tracing(trace).timing()
        if let shareManager = BDPShareManager.shared() {
            shareManager.setShareEntry(.inner)
        } else {
            context.apiTrace.info("shareManager is nil")
        }
        guard let commonManager = BDPCommonManager.shared() else {
            context.apiTrace.error("commonManager is nil")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("commonManager is nil")
            callback(.failure(error: error))
            return
        }
        let hostVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        var scopes = [:] as [AnyHashable : Any]
        if let authorization = gadgetContext.authorization {
            scopes = authorization.source.orgAuthMap
        } else {
            context.apiTrace.info("authorization is nil")
        }
        let orgAuthMapState: EMAOrgAuthorizationMapState = BDPIsEmptyDictionary(scopes) ? .empty : .notEmpty
        let hasAuth = EMAOrgAuthorization.orgAuth(withAuthScopes: scopes, invokeName: "shareAppMessageDirectly")
        context.apiTrace.info("hasAuth: \(hasAuth)")
        let version:String
        if let commonManager = BDPCommonManager.shared(), let common = commonManager.getCommonWith(uniqueID) {
            version = common.model.version ?? ""
        } else {
            context.apiTrace.info("commonManager is nil?:\(BDPCommonManager.shared() == nil)")
            version = ""
        }
        func common() -> BDPCommon? {
            if let commonManager = BDPCommonManager.shared(), let common = commonManager.getCommonWith(uniqueID) {
                return common
            }
            context.apiTrace.info("commonManager is nil? :\(BDPCommonManager.shared() == nil)")
            return nil
        }
        OPMonitor(kEventName_mp_organization_api_invoke).setUniqueID(uniqueID).tracing(trace)
            .addCategoryValue("api_name", "chooseChat")
            .addCategoryValue("auth_name", "chatInfo")
            .addCategoryValue("has_auth", "\(hasAuth)")
            .addCategoryValue("app_version", version)
            .addCategoryValue("lark_version", hostVersion)
            .addCategoryValue("org_auth_map", "\(orgAuthMapState.rawValue)")
            .flush()
        let shareContext = BDPShareContext()
        shareContext.title = params.title;
        shareContext.query = params.path
        shareContext.appCommon = common()
        shareContext.linkTitle = params.linkTitle
        shareContext.extra = params.extra
        shareContext.withShareTicket = params.withShareTicket
        shareContext.templateId = params.templateId
        shareContext.desc = params.desc
        shareContext.pcPath = params.PCPath
        shareContext.pcMode = params.PCMode
        let imageUrl = params.imageUrl
        if imageUrl.hasPrefix("http://") || imageUrl.hasPrefix("https://") {
            shareContext.imageUrl = imageUrl
        } else {
            // OC 类型声明为 nonnull，后续使用需要保证访问安全，原逻辑有风险。
            // 设置为空串，后续逻辑有处理，imageUrl 为空时走截图逻辑
            shareContext.imageUrl = ""
            do {
                let file = try FileObject(rawValue: params.imageUrl)
                let fsContext = FileSystem.Context(
                    uniqueId: uniqueID,
                    trace: context.apiTrace,
                    tag: "shareAppMessageDirectly",
                    isAuxiliary: true
                )

                let systemFilePath = try FileSystemCompatible.getSystemFile(from: file, context: fsContext)

                shareContext.imageUrl = URL(fileURLWithPath: systemFilePath).absoluteString
            } catch let error as FileSystemError {
                context.apiTrace.error("get system file path failed", error: error)
            } catch {
                context.apiTrace.error("get system file path unknown failed", error: error)
            }
        }
        shareContext.channel = params.channel
        shareContext.controller = gadgetContext.controller
        /// 如果开发者传的imageUrl为非空字符串，但是context的imageUrl未空，说明开发者传的为非法路径
        if !params.imageUrl.isEmpty && shareContext.imageUrl.isEmpty {
            context.apiTrace.error("Illegal imageUrl., app=\(uniqueID), auth:\(hasAuth), imageurl:\(params.imageUrl)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("Illegal imageUrl.")
            callback(.failure(error: error))
            if let controller = gadgetContext.controller {
                TMACustomHelper.showCustomToast(BDPI18n.share_fail_retry, icon: nil, window: controller.view.window)
            } else {
                context.apiTrace.info("controller is nil")
            }
            monitor.setResultTypeFail().setMonitorCode(GDAPIMonitorCode.illegal_image_url).tracing(trace).flush()
            return
        }
        if let shareManager = BDPShareManager.shared() {
            shareManager.onShareBegin(shareContext)
        } else {
            context.apiTrace.info("shareManager is nil")
        }
        guard let sharePlugin = BDPTimorClient.shared().sharePlugin.sharedPlugin() as? BDPSharePluginDelegate else {
            context.apiTrace.error("sharePlugin is nil")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("sharePlugin is nil")
            callback(.failure(error: error))
            return
        }
        sharePlugin.bdp_showShareBoard(with: shareContext, didComplete: { (result, channel, error, shareTicketResponse) in
            var resultType = BDPShareResultType.fail;
            if result == .success {
                resultType = .success
                if shareContext.withShareTicket {
                    callback(.success(data: OpenPluginShareAppMessageDirectlyResult.init(data: shareTicketResponse ?? [:])))
                } else {
                    callback(.success(data: nil))
                }
            } else if (result == .failed) {
                resultType = .fail
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setOuterMessage("result is fail ")
                callback(.failure(error: error))
            } else if (result == .cancel) {
                resultType = .cancel
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setOuterMessage("cancel ")
                callback(.failure(error: error))
            }
            if let shareManager = BDPShareManager.shared() {
                var errorMessage = ""
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    context.apiTrace.info("error is nil")
                }
                shareManager.onShareDone(resultType, errMsg: errorMessage)
            } else {
                context.apiTrace.info("shareManager is nil")
            }
            monitor.addCategoryValue("channel", channel)
            context.apiTrace.info("share imageurl invalid,result:\(result) app=\(uniqueID), auth:\(hasAuth), error:\(String(describing: error))")
            if result == .success {
                monitor.setResultTypeSuccess().tracing(trace).timing().flush()
            } else if (result == .failed) {
                monitor.setResultTypeFail().tracing(trace).setMonitorCode(GDMonitorCode.fail).setError(error).flush()
            } else if (result == .cancel){
                monitor.setResultTypeCancel().tracing(trace).setMonitorCode(GDMonitorCode.cancel).setError(error).flush()
            } else {
                monitor.setResultTypeFail().tracing(trace).setMonitorCode(GDMonitorCode.fail).setError(error).flush()
            }
        })
    }
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "shareAppMessageDirectly", pluginType: Self.self, paramsType: OpenPluginShareAppMessageDirectlyParams.self, resultType: OpenPluginShareAppMessageDirectlyResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.shareAppMessageDirectly(params: params, context:context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
