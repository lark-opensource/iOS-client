//
//  OpenPluginNetwork.swift
//  OPPlugin
//
//  Created by MJXin on 2021/8/26.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbe
import OPSDK
import LarkRustClient
import RustPB
import RxSwift
import LarkContainer
import LKCommonsLogging
import OPFoundation
import OPJSEngine

private let OpenAPIFeatureGatingKeyNetworkquality = "openplatform.api.networkquality"

final class OpenAPINetworkQualityResult: OpenAPIBaseResult {
    /// 网络质量类型
    public let networkQualityType: String
    /// 初始化方法
    public init(networkQualityType: String) {
        self.networkQualityType = networkQualityType
        super.init()
    }
    /// 返回打包结果
    public override func toJSONDict() -> [AnyHashable : Any] {
        return ["networkQualityType": networkQualityType]
    }
}

final class OpenPluginNetwork: OpenBasePlugin {
    typealias TraceID = String
    
    enum APIName: String {
        case getNetworkQualityType = "getNetworkQualityType"
        case offNetworkQualityChange = "offNetworkQualityChange"
        case onNetworkQualityChange = "onNetworkQualityChange"
        case onNetworkStatusChange = "onNetworkStatusChange"
        case offNetworkStatusChange = "offNetworkStatusChange"
        
        case request = "request"
        case requestAbort = "requestAbort"
        case uploadFile = "uploadFile"
        case uploadFileAbort = "uploadFileAbort"
        case downloadFile = "downloadFile"
        case downloadFileAbort = "downloadFileAbort"

        case requestPrefetch = "requestPrefetch"
        case getNetworkType
    }
    
    static let logger = Logger.oplog(OPNetStatusHelper.self, category: "OpenPluginNetwork")
    
    @Provider var statusService: OPNetStatusHelper // Global
    
    @ScopedProvider var rustService: RustService?
    
    @ScopedProvider var cookieService: ECOCookieService?
    
    var contextMap: [TraceID: OpenAPIContext] = [:]
    let lock = NSLock()
    
    let disposeBag = DisposeBag()
    var progressEventDisposable: Disposable?
    
    lazy var encodeSet: CharacterSet = {
        var charSet = CharacterSet.alphanumerics
        charSet.formIntersection(CharacterSet(charactersIn: "#:/;?+-.@&=%$_!*'(),{}|^~[]`<>\\\""))
        return charSet.inverted
    }()
    
    private var netStatus: OPNetStatusHelper.OPNetStatus = .unknown
    private var qualityContext: OpenAPIContext?
    private var networkStatusContext: OpenAPIContext?
    private let networkQualityGating: Bool = EMAFeatureGating.boolValue(forKey: OpenAPIFeatureGatingKeyNetworkquality)
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        
        if rustService == nil { Self.logger.error("resolve RustService failed") }
        if cookieService == nil { Self.logger.error("resolve ECOCookieService failed") }
        
        netStatus = statusService.status
        registerHandler()
        registerPushEvent()
        observeNetQuality()
        observeNetStatus()
    }
    
    private func registerHandler() {
        registerInstanceAsyncHandler(for: APIName.getNetworkQualityType.rawValue, pluginType: Self.self, resultType: OpenAPINetworkQualityResult.self) { this, params, context, callback in
            
            this.getNetworkQualityType(context: context, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: APIName.onNetworkQualityChange.rawValue, pluginType: Self.self) { (this, params, context, callback) in
            
            this.onNetworkQualityChange(context: context, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: APIName.offNetworkQualityChange.rawValue, pluginType: Self.self) { (this, params, context, callback) in
            
            this.offNetworkQualityChange(context: context, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: APIName.onNetworkStatusChange.rawValue, pluginType: Self.self) { (this, _, context, callback) in
            
            this.onNetworkStatusChange(context: context, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: APIName.offNetworkStatusChange.rawValue, pluginType: Self.self) { (this, _, context, callback) in
            
            this.offNetworkStatusChange(context: context, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: APIName.request.rawValue, pluginType: Self.self, paramsType: OpenPluginNetworkRequestParams.self) { (this, params, context, callback) in
            
            this.request(context: context, params: params, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: APIName.requestAbort.rawValue, pluginType: Self.self, paramsType: OpenPluginNetworkRequestParams.self) { (this, params, context, callback) in
            
            this.requestAbort(context: context, params: params, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: APIName.uploadFile.rawValue, pluginType: Self.self, paramsType: OpenPluginNetworkRequestParams.self) { (this, params, context, callback) in
            
            this.upload(context: context, params: params, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: APIName.uploadFileAbort.rawValue, pluginType: Self.self, paramsType: OpenPluginNetworkRequestParams.self) { (this, params, context, callback) in
            
            this.uploadAbort(context: context, params: params, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: APIName.downloadFile.rawValue, pluginType: Self.self, paramsType: OpenPluginNetworkRequestParams.self) { (this, params, context, callback) in
            
            this.download(context: context, params: params, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: APIName.downloadFileAbort.rawValue, pluginType: Self.self, paramsType: OpenPluginNetworkRequestParams.self) { (this, params, context, callback) in
            
            this.downloadAbort(context: context, params: params, callback: callback)
        }
        
        registerAsyncHandler(for: APIName.getNetworkType.rawValue, resultType: OpenPluginGetNetworkTypeResponse.self) {
            Self.getNetworkType(params: $0, context: $1, callback: $2)
        }
    }
    
    private func registerPushEvent() {
        // 注意对注册逻辑的兼容处理
        progressEventDisposable = rustService?.register(pushCmd: Command.openApiPushEvent) {[weak self] data in
            guard let self = self else {
                Self.logger.error("unexpect error self is nil")
                return
            }
            guard let rustEvent = try? Openplatform_Api_PushAPIEventData(serializedData: data),
                  let data = rustEvent.data.data(using: .utf8),
                  let progress = try? JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any] else {
                      Self.logger.error("serialized progress event data fail")
                return
            }

            let contextFromTraceId = self.getContextWithLock(by: rustEvent.apiContext.traceID)

            guard let context = contextFromTraceId,
                  let gadgetContext = context.gadgetContext,
                  rustEvent.apiContext.appID == gadgetContext.uniqueID.appID else {
                Self.logger.error("context for \(rustEvent.apiContext.traceID) not found")
                return
            }
            guard let fireEvent = try? OpenAPIFireEventParams(
                event: rustEvent.event,
                sourceID: NSNotFound,
                data: progress,
                preCheckType: .shouldInterruption,
                sceneType: .normal
            ) else {
                    context.apiTrace.error("create OpenAPIFireEventParams fail")
                    return
            }
            let _ = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
        }
    }
    
    private func observeNetQuality() {
        guard networkQualityGating else {
            Self.logger.info("Miss network quality gating")
            return
        }
        NotificationCenter.default.addObserver(self, selector: #selector(updateNetQualityType), name: Notification.Name.UpdateNetStatus, object: nil)
    }
    
    private func observeNetStatus() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateNetworkStatus), name: OPJSEngineService.shared.utils?.reachabilityChangedNotification(), object: nil)
    }
    
    @objc private func updateNetworkStatus() {
        guard let context = networkStatusContext else {
            Self.logger.info("NetworkStatus context is nil, don't need fire event")
            return
        }
        do {
            let fireEvent = try OpenAPIFireEventParams(event: "onNetworkStatusChange",
                                                       sourceID: NSNotFound,
                                                       data: ["isConnected": OPJSEngineService.shared.utils?.currentNetworkConnected() ?? false, "networkType": OPJSEngineService.shared.utils?.currentNetworkType() ?? ""],
                                                       preCheckType: .shouldInterruption,
                                                       sceneType: .normal)
            let _ = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)

        } catch {
            context.apiTrace.error("SyncCall fireEvent NetworkStatus error:\(error)")
        }
    }
    
    
    @objc private func updateNetQualityType() {
        guard netStatus != statusService.status else { return }
        netStatus = statusService.status
        fireNetworkQualityChangeIfNeed(type: netStatus.rawValue)
    }
    
    private func fireNetworkQualityChangeIfNeed(type: String) {
        guard let context = qualityContext else {
            Self.logger.info("FireNetworkQualityChange context is nil, don't need fire event")
            return
        }
        do {
            let fireEvent = try OpenAPIFireEventParams(event: "onNetworkQualityChange",
                                                       sourceID: NSNotFound,
                                                       data: ["networkQualityType": type],
                                                       preCheckType: .shouldInterruption,
                                                       sceneType: .normal)
            let _ = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
        } catch {
            context.apiTrace.error("SyncCall fireEvent onNetworkQualityChange error:\(error)")
        }
    }
    
    private func onNetworkStatusChange(context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("onNetworkStatusChange")
        networkStatusContext = context
        callback(.success(data: nil))
    }
    
    private func offNetworkStatusChange(
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("offNetworkStatusChange")
        networkStatusContext = nil
        callback(.success(data: nil))
    }
    
    public func getNetworkQualityType(
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPINetworkQualityResult>) -> Void) {
        guard networkQualityGating else {
            context.apiTrace.info("Miss network quality gating")
            callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unable).setErrno(OpenAPICommonErrno.unable)))
            return
        }
        context.apiTrace.info("GetNetworkQualityType value = \(netStatus.rawValue)")
        callback(.success(data: OpenAPINetworkQualityResult(networkQualityType: netStatus.rawValue)))
    }
    
    public func onNetworkQualityChange(
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard networkQualityGating else {
            context.apiTrace.info("Miss network quality gating")
            callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unable).setErrno(OpenAPICommonErrno.unable)))
            return
        }
        context.apiTrace.info("OnNetworkQualityChange")
        qualityContext = context
        callback(.success(data: nil))
    }
    
    public func offNetworkQualityChange(
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard networkQualityGating else {
            context.apiTrace.info("Miss network quality gating")
            callback(.failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unable).setErrno(OpenAPICommonErrno.unable)))
            return
        }
        context.apiTrace.info("OffNetworkQualityChange")
        qualityContext = nil
        callback(.success(data: nil))
    }
    
    static func getNetworkType(
        params: OpenAPIBaseParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginGetNetworkTypeResponse>) -> Void) {
            let networkType = BDPCurrentNetworkType()
            context.apiTrace.info("getNetworkType: \(networkType)")
            callback(.success(data: .init(networkType: .init(rawValue: networkType) ?? .unknown)))
    }
    
    private func unregisterAllEvent() {
        progressEventDisposable?.dispose()
        NotificationCenter.default.removeObserver(self)
    }

    func getContextWithLock(by traceId: TraceID) -> OpenAPIContext? {
        var context: OpenAPIContext? = nil
        lock.lock()
        context = contextMap[traceId]
        lock.unlock()
        return context
    }

    /// context为nil时，表示remove该context
    func setContextWithLock(_ context: OpenAPIContext?, by traceId: TraceID) {
        lock.lock()
        if let ctx = context {
            contextMap[traceId] = ctx
        } else {
            contextMap.removeValue(forKey: traceId)
        }
        lock.unlock()
    }
    
    deinit { unregisterAllEvent() }
}
