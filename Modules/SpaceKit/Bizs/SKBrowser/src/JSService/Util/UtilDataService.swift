//  Created by Songwen Ding on 2018/5/10.

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface
import SKInfra

public final class UtilDataService: BaseJSService {
    private var hasStartFetchClientVar = false
    private var hasEndFetchClientVar = false
    private var hasMarkClientVarCacheInfo = false
    lazy private var newCacheAPI = DocsContainer.shared.resolve(NewCacheAPI.self)!

    private lazy var baseDataPlugin: BaseDataPlugin = {
        let plugInConfig = SKBaseDataPluginConfig(cacheService: newCacheAPI, model: model)
        let plugin = BaseDataPlugin(plugInConfig)
        plugin.logPrefix = model?.jsEngine.editorIdentity ?? ""
        plugin.pluginProtocol = self
        return plugin
    }()

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension UtilDataService: BrowserViewLifeCycleEvent {
    public func browserWillClear() {
        hasStartFetchClientVar = false
        hasEndFetchClientVar = false
        hasMarkClientVarCacheInfo = false
    }
}

extension UtilDataService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return baseDataPlugin.handleServices
    }

    public func handle(params: [String: Any], serviceName: String) {
        self.baseDataPlugin.handle(params: params, serviceName: serviceName)
    }
    
    func markFetchNativeClientVarStartIfNeeded(_ key: String, path: String) {
        if isClientVarService(key, path: path), hasStartFetchClientVar == false {
            spaceAssert(hasEndFetchClientVar == false)
            OpenFileRecord.startRecordTimeConsumingFor(sessionID: model?.browserInfo.openSessionID, stage: OpenFileRecord.Stage.getNativeData.rawValue, parameters: nil)
            hasStartFetchClientVar = true
            
            if let traceRootId = (self.navigator?.currentBrowserVC as? SKTracableProtocol)?.traceRootId {
                SKTracing.shared.startChild(spanName: SKBrowserTrace.getNativeData, rootSpanId: traceRootId, component: LogComponents.fileOpen)
            }
        }
    }
    
    internal func markFetchNativeClientVarEndIfNeeded(_ key: String, path: String) {
        if isClientVarService(key, path: path), hasEndFetchClientVar == false {
            OpenFileRecord.endRecordTimeConsumingFor(sessionID: model?.browserInfo.openSessionID, stage: OpenFileRecord.Stage.getNativeData.rawValue, parameters: nil)
            spaceAssert(hasStartFetchClientVar == true)
            hasEndFetchClientVar = true
            
            if let traceRootId = (self.navigator?.currentBrowserVC as? SKTracableProtocol)?.traceRootId {
                SKTracing.shared.endSpan(spanName: SKBrowserTrace.getNativeData, rootSpanId: traceRootId, component: LogComponents.fileOpen)
            }
        }
    }

     func setFetchClientVarCacheMetaInfoIfNeededFor(key: String, objToken: String, result fetchedData: Any) {
        guard hasMarkClientVarCacheInfo == false else { return }
        hasMarkClientVarCacheInfo = true
        let cacheKey = "\(key):\(objToken)"
        let fetchFail = (fetchedData as? String) == ""
        var infoToUser = "fetch local clientVar end, \(fetchFail ? "failed" : "success")"
        defer { model?.openRecorder.appendInfo(infoToUser) }
        guard let info = ClientVarCacheInfoManager.shared.getInfoFor(cacheKey) else { return }
        OpenFileRecord.setClientVarCacheInfo(info, for: model?.browserInfo.openSessionID)
        infoToUser.append(" cache from \(info.source.rawValue)")
    }

    private func isClientVarService(_ key: String, path: String) -> Bool {
        return key.contains("CLIENT_VARS")
    }
}

extension UtilDataService: BaseDataPluginProtocol {
    func plugin(_ plugin: BaseDataPlugin, setNeedSync needSync: Bool, for objToken: String, type: DocsType) {
        model?.synchronizer.setNeedSync(needSync, for: objToken, type: type)
    }

    var currentIdentifier: String? {
        return model?.browserInfo.openSessionID
    }

    public func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {

        self.model?.jsEngine.callFunction(function, params: params, completion: completion)
    }

}
