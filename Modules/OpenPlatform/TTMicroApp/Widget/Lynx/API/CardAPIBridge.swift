//
//  CardAPIBridge.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/5/24.
//

import Foundation
import Lynx
import ECOInfra
import ECOProbe
import OPPluginManagerAdapter

let lynxNameInvoke = "invoke"
let lynxModuleName = "BDLynxModule"

/// 卡片 JS桥接层
@objcMembers
final class CardAPIBridge: NSObject, LynxModule {

    /// 卡片JSBridge引擎
    weak public var engine: CardEngine?

    /// Module Name
    public static var name: String = lynxModuleName //  bd_core.js 规定需要使用这个名字，勿动

    /// Module methods look up table. The keys are JS method names, while values are Objective C selectors.
    public static var methodLookup: [String : String] = [
        lynxNameInvoke: NSStringFromSelector(#selector(invoke(name:param:callback:)))
    ]

    var pluginManager: OPPluginManagerAdapter?

    public required override init() {
        super.init()
    }

    public required init(param: Any) {
        BDPLogInfo(tag: .cardApi, "CardAPIBridge init")
        if let cardEngine = param as? CardEngine {
            engine = cardEngine
            pluginManager = OPPluginManagerAdapter(with: cardEngine, type: .widget)
        } else {
            let msg = "CardAPIBridge init without CardEngine"
            assertionFailure(msg)
            BDPLogError(tag: .cardApi, msg)
        }
        super.init()
    }

    /// 收到卡片js调用（Lynx通过runtime调用invoke方法，需要加上dynamic进行修饰让这个方法支持动态派发）
    /// - Parameters:
    ///   - name: js方法名
    ///   - param: 参数
    ///   - callback: 回调
    dynamic public func invoke(
        name: String!,
        param: [AnyHashable : Any]!,
        callback: LynxCallbackBlock?
    ) {
        let receiveJSInvoke = OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_receive_invoke)
        let callbackJS = OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_callback_invoke)
        guard let engine = engine,
            var apiName = name,
            !apiName.isEmpty,
            let pluginManager = pluginManager else {
            BDPLogError(tag: .cardApi, "api name is empty")
            receiveJSInvoke.addMap(["app_type": "block"]).flush()
            callbackJS.setResultTypeFail().addMap(["app_type": "block",
                                                   "innerMsg":"internalError, name is nil: \(name == nil), engine is nil? \(self.engine == nil), pluginManager is nil \(self.pluginManager == nil)"]).flush()
            return
        }
        
        // 拦截器 用于在需要的时候修改 event 和 param
        let method = BDPJSBridgeMethod(name: apiName, params: param)
        do {
            try pluginManager.invokeInterceptorChain.preInvoke(method: method, extra: nil)
        } catch {
            BDPLogError(tag: .cardApi, "invokeInterceptorChain preInvoke \(method) error: \(error)")
        }
        apiName = method.name
        let param = method.params ?? [:]
        let appTrace = BDPTracingManager.sharedInstance().getTracingBy(engine.uniqueID)
        let trace = OPTraceService.default().generateTrace(withParent: appTrace, bizName: apiName)
        receiveJSInvoke
            .setUniqueID(engine.uniqueID)
            .addMap(["api_name": apiName,
                     "params.count": param.count])
            .flushTo(trace)
        callbackJS.setUniqueID(engine.uniqueID)
        BDPLogInfo(tag: .cardApi, "recive lynx api invoke with name: \(apiName)")
        //  派发到小程序目前的API
        pluginManager.invokeAPI(method: method, trace: trace, engine: engine, callback: { (status, data) in
            OPAPIReportResult(status, data, callbackJS.monitorEvent)
            callbackJS.flushTo(trace)
            trace.finish()
            callback?(data ?? [:])
        })
    }
}
