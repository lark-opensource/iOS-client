//
//  OpenPluginOpenBot.swift
//  OPPlugin
//
//  Created by lilun.ios on 2021/4/22.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbe
import OPSDK
import OPFoundation
import LarkContainer
import LarkOPInterface
import LarkSetting

final class OpenPluginOpenBot: OpenBasePlugin {
    
    @ScopedProvider var openApiService: LarkOpenAPIService?
    
    lazy var apiUniteOpt: Bool = {
        userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.open.interface.api.unite.opt")
    }()
    
    func enterBot(
        with params: OpenAPIBaseParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)
    {
        /// 通用错误回调方法
        let errorCallBack: ((String, OpenAPICommonErrorCode, OpenAPIErrnoProtocol) -> Void) = { (errorMsg, code, errno) in
            let error = OpenAPIError(code: code)
                .setErrno(errno)
                .setMonitorMessage(errorMsg)
            callback(.failure(error: error))
            context.apiTrace.error("enterBot fail \(errorMsg) \(code)")
        }
        let trace = BDPTracingManager.sharedInstance().getTracingBy(gadgetContext.uniqueID)
        let monitor = OPMonitor(kEventName_mp_enter_bot)
            .setUniqueID(gadgetContext.uniqueID)
            .tracing(trace)
            .timing()
        guard let common = BDPCommonManager.shared()?.getCommonWith(gadgetContext.uniqueID),
              let model = OPUnsafeObject(common.model),
              let extraDict = OPUnsafeObject(model.extraDict),
              let botId = extraDict["botid"] else {
            /// 错误的message信息对齐EMAPluginChat
            errorCallBack("No Bot.", .unknown, OpenAPIChatErrno.NoBotId)
            context.apiTrace.error("uniqueID: \(gadgetContext.uniqueID) has no botid")
            monitor.setResultTypeFail()
                .addCategoryValue("fail_type", "botId_empty")
                .timing()
                .flush()
            return
        }
        
        if self.apiUniteOpt {
            let botIdStr = "\(botId)"
            let window = gadgetContext.controller?.view.window ?? gadgetContext.uniqueID.window
            guard let openApiService = self.openApiService else {
                let callBackMsg = "lark has not openApiService impl"
                errorCallBack(callBackMsg, .unknown, OpenAPICommonErrno.unknown)
                monitor.setResultTypeFail()
                    .addCategoryValue("fail_type", "openApiService impl is empty")
                    .timing()
                    .flush()
                return
            }
            let from = OPNavigatorHelper.topmostNav(window: window)
            openApiService.enterBot(botID: botIdStr, from: from)
            callback(.success(data: nil))
            monitor.setResultTypeSuccess().timing().flush()
            context.apiTrace.info("enterBot finish success")
        } else {
            guard let enterBotBlock = EMARouteMediator.sharedInstance().enterBotBlock else {
                /// 错误的message信息对齐EMAPluginChat
                let callBackMsg = "lark has not impl enterBotBlock"
                errorCallBack(callBackMsg, .unknown, OpenAPICommonErrno.unknown)
                monitor.setResultTypeFail()
                    .addCategoryValue("fail_type", "botBlock_emtpy")
                    .timing()
                    .flush()
                return
            }
            let botIdStr = "\(botId)"
            enterBotBlock(botIdStr, gadgetContext.uniqueID, gadgetContext.controller)
            callback(.success(data: nil))
            monitor.setResultTypeSuccess().timing().flush()
            context.apiTrace.info("enterBot finish success")
        }
    }
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "enterBot", pluginType: Self.self,
                             paramsType: OpenAPIBaseParams.self,
                             resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.enterBot(with: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}

