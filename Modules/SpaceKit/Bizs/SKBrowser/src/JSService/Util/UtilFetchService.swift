//  Created by Songwen Ding on 2018/5/10.

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import SKInfra

public final class UtilFetchService: BaseJSService {
    lazy var baseFetchPlugin: SKBaseFetchPlugin = {
        let config = SKBaseFetchPluginConfig(netServiceType: DocsRequest<Any>.self, execJSService: self)
        let plugin = SKBaseFetchPlugin(config)
        plugin.pluginProtocol = self
        plugin.logPrefix = model?.jsEngine.editorIdentity ?? ""
        return plugin
    }()

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }

    deinit {
        reset()
    }

    func reset() {
        baseFetchPlugin.cancelAllTask()
    }

}

extension UtilFetchService: BrowserViewLifeCycleEvent {
    public func browserWillClear() {
        reset()
    }
}

extension UtilFetchService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return baseFetchPlugin.handleServices
    }

    public func handle(params: [String: Any], serviceName: String) {
        baseFetchPlugin.handle(params: params, serviceName: serviceName)
    }

    private func reportFetchStartToUserIfNeed(_ request: URLRequest) {
        if request.url?.path.contains("/api/rce/message") ?? false {
            let info = "start fetch \(request.url!.path)"
            model?.openRecorder.appendInfo(info)
            DocsLogger.info(info)
        }
    }

    private func reportFetchEndToUserIfNeed(_ response: URLResponse?, errorCode: Int) {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        if httpResponse.url?.path.contains("/api/rce/message") ?? false {
            let info = "end fetch \(httpResponse.url?.path ?? ""), code \(errorCode), x-tt-logid \(httpResponse.allHeaderFields[DocsCustomHeader.xttLogId.rawValue] ?? "")"
            model?.openRecorder.appendInfo(info)
            DocsLogger.info(info)
        }
    }
}

extension UtilFetchService: SKBaseFetchPluginProtocol, SKExecJSFuncService {
    public func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {

        guard let model = model else {
            DocsLogger.info("fetch callback model nil, callback:\(function.rawValue)")
            return
        }
        model.jsEngine.callFunction(function, params: params, completion: completion)
    }

    var additionalRequestHeader: [String: String] {
        return model?.requestAgent.requestHeader ?? [:]
    }

    func didStartFetch(_ request: URLRequest) {
        reportFetchStartToUserIfNeed(request)
    }

    func didEndFetch(_ response: URLResponse?, errorCode: Int) {
        reportFetchEndToUserIfNeed(response, errorCode: errorCode)
    }
    func modifiedUrlFor(_ url: URL) -> URL {
        let url = DocsUrlUtil.changeUrlForNewDomain(url, webviewUrl: model?.browserInfo.currentURL)
        var urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponent.scheme = OpenAPI.docs.currentNetScheme
        return urlComponent.url ?? url
    }
}
