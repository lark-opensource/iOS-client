//
//  OPBlockAPIAdapterPlugin.swift
//  EEMicroAppSDK
//
//  Created by yinyuan on 2020/11/17.
//

import Foundation
import TTMicroApp
import LKCommonsLogging
import OPSDK
import LarkFeatureGating
import OPBlock
import LarkOpenPluginManager
import OPPluginManagerAdapter

/// 专用于解决小程序API快速适配 Block，后期统一API架构后移除
///
/// 适配 API 需要进行以下事情：
/// 1. 在 registerInstanceMethod 添加 type: BDPJSBridgeMethodTypeBlock
/// 2. 在下面枚举中增加该 API
/// 3. 去对应的 API 检查逻辑是否兼容并进行适配
public enum BlockAdaptedAPIName: String {
    case login
    case getUserInfo
    case createRequestTask
    case operateRequestTask
    case createSocketTask
    case operateSocketTask
    case enterProfile
    //    case onWindowResize 该API通过 fireEvent 方式通知前端，由前端对外提供API，配套的有 offWindowResize
    //    case getHostInfo 新增一个API，基于 getSystemInfo 裁剪
    case getSystemInfo
    case getSystemInfoSync
    case openSchema
    case chooseChat
    case chooseContact
    case chooseImage
    case showToast
    case hideToast
    case showModal
    //    case showLoading 该API应该是前端基于 showToast 封装的语法糖?
    //    case hideLoading 该API应该是前端基于 hideToast 封装的语法糖?
    case docsPicker
    case monitorReport

    // storage API
    case setStorage
    case setStorageSync
    case getStorage
    case getStorageSync
    case removeStorage
    case removeStorageSync
    case getStorageInfo
    case getStorageInfoSync
    case clearStorage
    case clearStorageSync
    case saveLog
    case setContainerConfig
    case showBlockErrorPage
    case hideBlockErrorPage
    case getEnvVariable
    case getKAInfo
    case onServerBadgePush
    case offServerBadgePush
    case openLingoProfile
    case request
    case getUserCustomAttr
    case invokeCustomAPI
    case getLocation
    case startLocationUpdate
    case stopLocationUpdate
    case getNetworkType
    case getConnectedWifi
}

private let logger = Logger.oplog(OPBlockAPIAdapterPlugin.self, category: "OPBlockAPIAdapterPlugin")

/// 专用于解决小程序API快速适配 Block，后期统一API架构后移除
public final class OPBlockAPIAdapterPlugin: OPPluginBase {
    
    public required init(apis: [BlockAdaptedAPIName]) {
        super.init()
        filters = apis.map { (apiName) -> String in
            apiName.rawValue
        }
    }
    
    public override func handleEvent(event: OPEvent, callback: OPEventCallback) -> Bool {
        guard let containerContext = event.context.containerContext else {
            return false
        }
        let uniqueID = containerContext.uniqueID
        
        let name = event.eventName
        
        let appTrace = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)
        let trace = OPTraceService.default().generateTrace(withParent: appTrace, bizName: name)
        let blockEngine = createEngineIfNeeded(containerContext: containerContext, event: event)
        let pluginManager = createPluginManagerIfNeeded(containerContext: containerContext, blockEngine: blockEngine)
        
        // 构造方法
        let method = BDPJSBridgeMethod(name: event.eventName, params: event.params)
        // 拦截器 用于在需要的时候修改 event 和 param
        do {
            try pluginManager.invokeInterceptorChain.preInvoke(method: method, extra: nil)
        } catch {
            logger.error("invokeInterceptorChain preInvoke \(method) error: \(error)")
        }
        
        let host = containerContext.uniqueID.host

        OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_receive_invoke)
            .setUniqueID(uniqueID)
            .addCategoryValue(kEventKey_api_name, method.name)
            .addCategoryValue("app_type", OpenAPIBizType.block.rawValue)
            .addCategoryValue("host", host)
            .addCategoryValue("use_plugin", false)
            .flushTo(trace)

        let callbackInvoke = OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_callback_invoke)
        
        guard let eventName = BlockAdaptedAPIName(rawValue: name) else {
            callbackInvoke
                .setResultTypeFail()
                .addMap(["innerMsg": "block don't support api \(name)"])
                .flushTo(trace)
            trace.finish()
            return false
        }
        
        // 调用
        let extraContext = ["blockEvent": event]
        pluginManager.invokeAPI(method: method, trace: trace, engine: blockEngine, contextExtra: extraContext, source: nil) { (callBackType, params) in
            OPAPIReportResult(callBackType, params, callbackInvoke.monitorEvent)
            callbackInvoke.flushTo(trace)
            trace.finish()
            switch callBackType {
            case .success:
                callback.callbackSuccess(data: params)
            case .noHandler, .noHostHandler:
                callback.callbackNoHandler(data: params)
            case .userCancel:
                callback.callbackCancel(data: params, error: nil)
            default:
                callback.callbackFail(data: params, error: nil)
            }
        }
        
        return true
    }
    private func createEngineIfNeeded(containerContext: OPContainerContext, event: OPEvent) -> OPBlockEngine {
        // 找到绑定的 BlockEngine 对象，如果没有找到首次创建并关联
        var blockEngine: OPBlockEngine
        let uniqueID = containerContext.uniqueID
        if let aEngine = containerContext.blockEngine {
            blockEngine = aEngine
        } else {
            blockEngine = OPBlockEngine(containerContext: containerContext)
            containerContext.blockEngine = blockEngine
        }
        // 每次 API 调用前都更新设置
        blockEngine.bridgeController = event.context.presentBasedViewController
        blockEngine.bridge = event.context.bridge
        return blockEngine
    }
    
    private func createPluginManagerIfNeeded(containerContext: OPContainerContext,
                                             blockEngine: OPBlockEngine) -> OPPluginManagerAdapter {
        // 找到绑定的 pluginManager 对象，如果没有找到首次创建并关联
        if let pluginManager = containerContext.pluginManager {
            return pluginManager
        }
        let pluginManager = OPPluginManagerAdapter(with: blockEngine,
                                                   type: .block,
                                                   bizScene: containerContext.blockScene)
        pluginManager.blockRegisterPoint()
        pluginManager.invokeInterceptorChain.register(inteceptor: OpenApiBlockDispatchInvokeInterceptor())
        containerContext.pluginManager = pluginManager
        return pluginManager
    }
}

private var opAppContainerContextBlockEngine: Void?
private var opPluginManagerAdapter: Void?

extension OPContainerContext {
    
    var pluginManager: OPPluginManagerAdapter? {
        get {
            return objc_getAssociatedObject(self, &opPluginManagerAdapter) as? OPPluginManagerAdapter
        }
        set {
            objc_setAssociatedObject(
                self,
                &opPluginManagerAdapter,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var blockEngine: OPBlockEngine? {
        get {
            return objc_getAssociatedObject(self, &opAppContainerContextBlockEngine) as? OPBlockEngine
        }
        set {
            objc_setAssociatedObject(
                self,
                &opAppContainerContextBlockEngine,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
}

