//
//  OPPluginDiagnose.swift
//  OPPlugin
//
//  Created by qsc on 2021/7/4.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPFoundation
import OPPluginBiz
import OPPluginManagerAdapter
import LarkContainer

final class OpenPluginDiagnose: OpenBasePlugin {

    func execDiagnoseCommands(params: OpenAPIExecDiagnoseCommandsParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        

        // 检查 diagnose API FG
        guard EMAFeatureGating.boolValue(forKey: EMAFeatureGatingKeyMicroAppDiagnoseApiEnable) else {
            context.apiTrace.warn("api is unuseable")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setMonitorMessage("api is not available")
            callback(.failure(error: error))
            return
        }

        // 检查 diagnose API 调用白名单
        guard let appEngine = (BDPTimorClient.shared().appEnginePlugin.sharedPlugin() as? EMAAppEnginePluginDelegate),
              appEngine.onlineConfig?.isApiAvailable("execDiagnoseCommands", for: gadgetContext.uniqueID) ?? false else {
            context.apiTrace.warn("api is not availablef for current app")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setMonitorMessage("api is not available for current app")
            callback(.failure(error: error))
            return
        }

        // 执行诊断 API，这里通过 EMAPluginDiagnose 暴露的外部接口执行
        let diagnose = EMAPluginDiagnose.init()
        let resp = diagnose.execDiagnoseCommandsSwiftWrapper(params.commands, controller: gadgetContext.controller ?? nil)
        // 调用结束，返回结果
        let result = OpenAPIExecDiagnoseCommandsResult(result: resp)
        callback(.success(data: result))
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "execDiagnoseCommands", pluginType: Self.self, paramsType: OpenAPIExecDiagnoseCommandsParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.execDiagnoseCommands(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }

}
