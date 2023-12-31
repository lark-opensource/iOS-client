//
//  OpenAPIReportJsRuntimeError.swift
//  OPPlugin
//
//  Created by 窦坚 on 2021/7/5.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LarkContainer

final class OpenAPIReportJsRuntimeError: OpenBasePlugin {

    static var reportEngine: NSHashTable = NSHashTable<AnyObject>.weakObjects();

    public func reportJsRuntimeError(params: OpenAPIReportJsRuntimeErrorModel, context: OpenAPIContext, gadgetContext: OPAPIContextProtocol, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {

        guard let common: BDPCommon = BDPCommonManager.shared()?.getCommonWith(gadgetContext.uniqueID) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage("common is nil")
            callback(.failure(error: error))
            return
        }

        // 只上报一次 https://bytedance.feishu.cn/space/doc/doccn5Idls8LhSTtBjryPazy5vh
        // 未启动 ready 之前都需要上报
        if (!(OpenAPIReportJsRuntimeError.reportEngine.contains(gadgetContext)) || !(common.isReady)) {
            if (common.isReady) {
                OpenAPIReportJsRuntimeError.reportEngine.add(gadgetContext)
            }
            let message: String = params.message ?? ""
            let stack: String = params.stack ?? ""
            let errorType: String = params.errorType ?? ""
            let extend: String = params.extend ?? ""
            let worker: String = params.worker ?? ""

            let monitor = BDPMonitorEvent.init(service: nil, name: "mp_js_runtime_error", monitorCode: EPMClientOpenPlatformGadgetCode.js_runtime_error)
            monitor.setUniqueID()(gadgetContext.uniqueID)
                .addCategoryValue()("message", message)
                .addCategoryValue()("stack", stack)
                .addCategoryValue()("errorType", errorType)
                .addCategoryValue()("extend", extend)
                .addCategoryValue()("worker", worker)
                .setPlatform()([.tea,.slardar])
                .flush()

            context.apiTrace.info("report mp_js_runtime_error")
        } else {
            context.apiTrace.info("report mp_js_runtime_error cancelled.")
        }
        callback(.success(data: nil))
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "reportJsRuntimeError", pluginType: Self.self, paramsType: OpenAPIReportJsRuntimeErrorModel.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.reportJsRuntimeError(params: params, context: context,gadgetContext: gadgetContext, callback: callback)
        }
    }

}
