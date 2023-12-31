//
//  OpenPluginDebugger.swift
//  OPPlugin
//
//  Created by yi on 2021/2/18.
//

import Foundation
import TTMicroApp
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import LarkContainer

final class OpenPluginDebugger: OpenBasePlugin {
    
    @InjectedSafeLazy var debugger: EMADebuggerSharedService // Global

    func consoleLogOutput(params: OpenAPIConsoleLogOutputParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID
        let payload = params.payload
        let command = EMADebuggerLogCommand()
        if let timestampString = payload["timestamp"] as? String {
            command.timestamp = timestampString
        } else if let timestampNum = payload["timestamp"] as? NSNumber {
            command.timestamp = timestampNum.stringValue
        }
        command.level = payload["level"] as? String ?? ""
        if let levelString = payload["level"] as? String {
            command.level = levelString
        } else if let levelNum = payload["level"] as? NSNumber {
            command.level = levelNum.stringValue
        }

        if let tagString = payload["tag"] as? String {
            command.tag = tagString
        } else if let tagNum = payload["tag"] as? NSNumber {
            command.tag = tagNum.stringValue
        }

        if let contentString = payload["content"] as? String {
            command.content = contentString
        } else if let contentNum = payload["content"] as? NSNumber {
            command.content = contentNum.stringValue
        }

        if let common = BDPCommonManager.shared()?.getCommonWith(uniqueID) {
            if let commonUniqueID = OPUnsafeObject(common.uniqueID) {
                command.appId = OPUnsafeObject(commonUniqueID.appID) ?? ""
            }
            if let model = OPUnsafeObject(common.model) {
                command.appName = OPUnsafeObject(model.name) ?? ""
            }
        }
        debugger.pushCmd(command, for: uniqueID)
        callback(.success(data: nil))
    }

    func logManager(params: OpenAPILogManagerParams, context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("\(params.logParams)")
        callback(.success(data: nil))
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "consoleLogOutput", pluginType: Self.self, paramsType: OpenAPIConsoleLogOutputParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.consoleLogOutput(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandler(for: "logManager", pluginType: Self.self, paramsType: OpenAPILogManagerParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            

            this.logManager(params: params, context: context, callback: callback)
        }
    }
}
