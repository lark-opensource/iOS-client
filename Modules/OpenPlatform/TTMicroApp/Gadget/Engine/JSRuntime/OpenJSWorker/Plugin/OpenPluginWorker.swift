//
//  OpenPluginWorker.swift
//  OPPlugin
//
//  Created by yi on 2021/7/5.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPFoundation
import LarkContainer
import OPPluginManagerAdapter

final class OpenPluginWorker: OpenBasePlugin {

    // worker onMessage方法，JS注入的callback
    var onMessageCallback: JSValue?

    // worker间传递消息
    func workerTransferMessage(params: OpenAPIWorkerTransferMessageParams, context: OpenAPIContext, callback: @escaping(OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        if let onMessageCallback = onMessageCallback {
            context.apiTrace.info("workerTransferMessage success from source worker")
            onMessageCallback.call(withArguments: [params.data])
            callback(.success(data: nil))
        } else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError).setMonitorMessage("workerTransferMessage fail, callback is nil")
            callback(.failure(error: error))
            context.apiTrace.warn("workerTransferMessage fail, callback is nil")
        }
    }

    // 创建worker
    func createWorker(params: OpenAPIWorkerParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext) -> OpenAPIBaseResponse<OpenAPICreateWorkerResult> {
        let moduleDisable = EMAFeatureGating.boolValue(forKey: EEFeatureGatingKeyGadgetWorkerModuleDisable)
        if moduleDisable {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setMonitorMessage("not impl, fg not open").setOuterMessage("not impl")
            return .failure(error: error)
        }

        let workerID = params.key // worker id
        guard gadgetContext.enableCreateWorker(), gadgetContext.getWorker(workerID: workerID) == nil else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("exceed max concurrent workers limit.")
            return .failure(error: error)
        }

        // 注入OpenJSWorker的脚本下载解释器
        OpenJSWorkerInterpreterManager.shared.register(name: "comment_for_gadget", types: [OpenPluginCommnentJSManager.self])

        // 创建worker
        let extra = params.data ?? [:]
        guard let worker: OPSeperateJSRuntimeProtocol = gadgetContext.addWorker(workerID: workerID, data: extra) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
            return .failure(error: error)
        }

        worker.authorization = gadgetContext.authorization
        worker.uniqueID = gadgetContext.uniqueID
        worker.bridgeController = gadgetContext.controller

        // 返回worker对象给sourceWorker
        let postMessage: @convention(block) ([AnyHashable: Any]) -> Any? = { [weak worker] dic in
            guard let worker = worker else {
                context.apiTrace.warn("work is nil, transferMessage fail")
                return nil
            }
            if let transferMessage = worker.transferMessage {
                transferMessage(dic)
            } else {
                context.apiTrace.warn("work transferMessage func is nil, transferMessage fail")
            }
            return nil
        }

        let onMessage: (@convention(block) (JSValue?) -> Any?)? = { [weak self] callback in
            guard let `self` = self else {
                context.apiTrace.warn("self is nil, onMessage setup fail")
                return nil
            }

            self.onMessageCallback = callback
            return nil
        }

        let terminate: @convention(block) (JSValue?) -> Any? = {value in
            gadgetContext.terminateWorker(workerID: params.key)
            return nil
        }

        let result = OpenAPICreateWorkerResult()
        result.postMessage = postMessage
        result.onMessage = onMessage
        result.terminate = terminate
        return .success(data: result)
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)

        registerInstanceSyncHandlerGadget(for: "createWorker", pluginType: Self.self, paramsType: OpenAPIWorkerParams.self, resultType: OpenAPICreateWorkerResult.self) { this, params, context, gadgetContext in
            return this.createWorker(params: params, context: context, gadgetContext: gadgetContext)
        }

        registerInstanceAsyncHandler(for: "workerTransferMessage", pluginType: Self.self, paramsType: OpenAPIWorkerTransferMessageParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.workerTransferMessage(params: params, context: context, callback: callback)
        }
    }
}
