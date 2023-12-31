//
//  OpenPluginBgAudio.swift
//  OPPlugin
//
//  Created by zhysan on 2022/5/9.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkSetting
import LKCommonsLogging
import OPPluginManagerAdapter
import TTMicroApp
import LarkContainer

struct OpenPluginHostPageURL: Equatable {
    let path: String
    let absoluteString: String
    let query: String
    let uniqueID: OPAppUniqueID
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.uniqueID == rhs.uniqueID && lhs.path == rhs.path
    }
}

let OPBGMLogger = Logger.oplog(OpenPluginBgAudio.self, category: "OpenPluginBgAudio")

final class OpenPluginBgAudio: OpenBasePlugin {
    
    // MARK: - lifecycle
    
    // 获取当前设备类型，不是 iPad 全是 iPhone
    private func isiPadDevice() -> Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var routeKVOToken: NSKeyValueObservation?
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        // iPad 设备不增加此能力
        if isiPadDevice() {
            OPBGMLogger.info("OpenPluginBgAudio isiPadDevice")
            return
        }

        // MARK: - sync handler registration
        registerInstanceSyncHandler(for: "getBackgroundAudioContextSync", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context) -> OpenAPIBaseResponse<OpenAPIBaseResult> in
            
            
            
            this.getBackgroundAudioContext(context)
            return .success(data: nil)
        }
        
        registerInstanceSyncHandler(for: "setBgAudioStateSync", pluginType: Self.self, paramsType: OPAPIParamSetBgAudioState.self, resultType: OpenAPIBaseResult.self) { (this, params, context) -> OpenAPIBaseResponse<OpenAPIBaseResult> in
            
            
            this.setBgAudioState(params, apiContext: context)
            return .success(data: nil)
        }
        
        registerInstanceSyncHandler(for: "getBgAudioStateSync", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OPAPIResultGetBgAudioState.self) { (this, params, context) -> OpenAPIBaseResponse<OPAPIResultGetBgAudioState> in
            
            
            
            return this.getBgAudioState(apiContext: context)
        }
        
        registerInstanceSyncHandler(for: "operateBgAudioSync", pluginType: Self.self, paramsType: OPAPIParamOperateBgAudio.self, resultType: OpenAPIBaseResult.self) { (this, params, context) -> OpenAPIBaseResponse<OpenAPIBaseResult> in
            
            
            
            do {
                try this.operateBgAudio(params, context: context)
                return .success(data: nil)
            } catch {
                return .failure(error: OpenAPIError(errno: OpenAPIBGAudioErrno.noneAudio))
            }
            
        }
        
    }
    
    override func onBackground() {
        OpenBGAudioCenter.shared.appEnterBackground()
    }
    
    override func onForeground() {
        OpenBGAudioCenter.shared.appEnterForeground()
    }
    
    func onHostPageChanged(url: OpenPluginHostPageURL) {
        if let apiContext = apiContext {
            OpenBGAudioCenter.shared.onHostPageChanged(url: url, apiContext: apiContext)
        }
    }
    
    deinit {
        apiContext?.apiTrace.info("deinit")
        OpenBGAudioCenter.shared.unregister(uniqueID: apiContext?.uniqueID)
    }
    
    
    private var apiContext: OpenAPIContext?
   
    func fireEvent(_ params: OpenAPIFireEventParams) {
        guard let ctx = apiContext else {
            OPBGMLogger.info("trigger event context nil")
            return
        }
        let _ = ctx.syncCall(apiName: "fireEvent", params: params, context: ctx)
    }
    
    // MARK: - api imp
    
    private func getBackgroundAudioContext(_ _apiContext: OpenAPIContext) {
        _apiContext.apiTrace.info("getBackgroundAudioContext")
        apiContext = _apiContext
        
        guard let uniqueID = _apiContext.uniqueID else { return }
        guard let task = BDPTaskManager.shared().getTaskWith(uniqueID) else { return }
        if routeKVOToken == nil {
            routeKVOToken = task.observe(\.currentPage) { [weak self] object, _ in
                guard let self = self else { return }
                if let page = object.currentPage {
                    let path = OpenPluginHostPageURL(path: page.path, absoluteString: page.absoluteString, query: page.queryString, uniqueID: uniqueID)
                    self.onHostPageChanged(url: path)
                }
            }
        }
    }
    
    
    private func setBgAudioState(_ state: OPAPIParamSetBgAudioState, apiContext _apiContext: OpenAPIContext) {
        _apiContext.apiTrace.info("setBgAudioState, src: \(String(describing: state.src))")
        OpenBGAudioCenter.shared.setState(state, apiContext: _apiContext, listener: self)
    }
    
    private func getBgAudioState(apiContext _apiContext: OpenAPIContext) -> OpenAPIBaseResponse<OPAPIResultGetBgAudioState> {
        do {
            _apiContext.apiTrace.info("getBgAudioState")
            return .success(data: try OpenBGAudioCenter.shared.getState(apiContext: _apiContext))
        } catch let error {
            _apiContext.apiTrace.error("getBgAudioState exec \(error)")
            return .failure(error: OpenAPIError(errno: OpenAPIBGAudioErrno.noneAudio))
        }
    }
    
    private func operateBgAudio(_ param: OPAPIParamOperateBgAudio, context _apiContext: OpenAPIContext) throws {
        _apiContext.apiTrace.info("operateBgAudio")
        try OpenBGAudioCenter.shared.operate(param, apiContext: _apiContext)
    }
}

extension OpenPluginBgAudio: OpenBGAudioCenterListener {
    func handleEvent(_ event: OpenBGAudioEvent, data: [AnyHashable: Any]?) {
        apiContext?.apiTrace.info("trigger event: \(event.rawValue)")
        do {
            let params = try OpenAPIFireEventParams(event: OpenBGAudioEvent.OpenBGAudioEventName,
                                                    data: event.stateData,
                                                    preCheckType: .none,
                                                    sceneType: .normal)
            fireEvent(params)
        } catch(let error) {
            apiContext?.apiTrace.error("[OPBGM] trigger event error: \(error)")
        }
    }
    
    func handleEvent(_ event: OpenBGAudioEvent) {
        handleEvent(event, data: nil)
    }
    
}
