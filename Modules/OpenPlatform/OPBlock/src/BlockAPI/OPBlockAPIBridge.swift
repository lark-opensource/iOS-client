//
//  OPBlockAPIBridge.swift
//  OPBlock
//
//  Created by xiangyuanyuan on 2022/8/12.
//

import Foundation
import TTMicroApp
import OPSDK
import LarkOpenPluginManager
import OPBlockInterface
import OPFoundation
import LarkOpenAPIModel
import OPPluginManagerAdapter

class OPBlockAPIBridge {
    
    private let pluginManager: OPPluginManagerAdapter
    
    private let blockEngine: OPBlockEngine
    
    private let containerContext: OPContainerContext
    
    public init(containerContext: OPContainerContext) {
        
        self.containerContext = containerContext
        self.blockEngine = OPBlockEngine(containerContext: containerContext)

        self.pluginManager = OPPluginManagerAdapter(with: self.blockEngine,
                                                    type: .block,
                                                    bizDomain: .openPlatform,
                                                    bizScene: containerContext.blockScene,
                                                    apiRegistrationFilter: { apiName, conditions in
            // block支持的API需要明确在plist中配置Type为block
            for condition in conditions {
                if condition.bizType == .block {
                    return true
                }
            }
            return false
        })
        self.pluginManager.blockRegisterPoint()
        self.pluginManager.invokeInterceptorChain.register(inteceptor: OpenApiBlockDispatchInvokeInterceptor())
    }
    
    public func invokeApi(
        apiName: String,
        param: [AnyHashable : Any],
        callback: @escaping BDPJSBridgeCallback
    ) {
        let uniqueID = containerContext.uniqueID
        let appTrace = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)
        let trace = OPTraceService.default().generateTrace(withParent: appTrace, bizName: apiName)
        
        let host = containerContext.uniqueID.host
        let type = (containerContext.meta as? OPBlockMeta)?.extConfig.pkgType.rawValue
        
        let container = OPApplicationService.current.getContainer(uniuqeID: uniqueID) as? OPBlockContainer
        self.blockEngine.bridge = container?.bridge
        self.blockEngine.bridgeController = container?.currentRenderSlot?.delegate?.currentViewControllerForPresent()

        let receiveJSInvoke = OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_receive_invoke)
            .addCategoryValue("app_type", OpenAPIBizType.block.rawValue)
            .addCategoryValue("host", host)
            .addCategoryValue("type", type)
            .addCategoryValue("param.length", param.count)
            .addCategoryValue("use_plugin", true)

        guard !apiName.isEmpty else {
            callback(.failed, nil)
            receiveJSInvoke.addMap(["innerMsg":"internalError, name is nil"]).flushTo(trace)
            trace.finish()
            return
        }
        receiveJSInvoke.addCategoryValue("api_name", apiName)
        
        // 构造方法
        let method = BDPJSBridgeMethod(name: apiName, params: param)
        do {
            try pluginManager.invokeInterceptorChain.preInvoke(method: method, extra: nil)
        } catch {
            trace.error("invokeInterceptorChain preInvoke \(method) error: \(error)")
            callback(.failed, nil)
            receiveJSInvoke.addMap(["innerMsg":"invokeInterceptorChain preInvoke \(method) error: \(error)"])
                .flushTo(trace)
            trace.finish()
        }
        
        receiveJSInvoke.flushTo(trace)
        
        let callbackJS = OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_callback_invoke)

        let extraContext = ["blockContainer": container] as? [String : Any]
        pluginManager.invokeAPI(method: method,
                                trace: trace,
                                engine: blockEngine,
                                contextExtra: extraContext,
                                source: nil) { (status, response) in
            OPAPIReportResult(status, response, callbackJS.monitorEvent)
            callbackJS.flushTo(trace)
            trace.finish()
            callback(status, response)
        }
    }
}

extension OpenAPIContext {
    var blockContainer: OPBlockContainer? {
        get {
            return additionalInfo["blockContainer"] as? OPBlockContainer
        }
    }
}

public extension OPContainerContext {
    var blockScene: String {
        let host = OPBlockHost(rawValue: uniqueID.host)
        let type = (meta as? OPBlockMeta)?.extConfig.pkgType
        
        switch host {
        case .workplace:
            switch type {
            case .blockDSL:
                return OPBlockScene.workplace_dsl.rawValue
            case .offlineWeb:
                return OPBlockScene.workplace_h5.rawValue
            case .none:
                return ""
            }
        case .search:
            switch type {
            case .blockDSL:
                return OPBlockScene.search_dsl.rawValue
            case .offlineWeb:
                return OPBlockScene.search_h5.rawValue
            case .none:
                return ""
            }
        case .none, .some(_):
            return ""
        }
    }
}
