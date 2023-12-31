//  Created by weidong fu on 5/2/2018.

import Foundation
import SKCommon
import SKFoundation

public final class UtilLoadingService: BaseJSService {
    enum State {
        case start
        case end
        case timeOut
    }

    func jsService(_ jsService: UtilLoadingService, setLoadingState state: UtilLoadingService.State) {
        switch state {
        case .end:
            model?.loadingReporter?.didHideLoading()
        default:
            spaceAssertionFailure("不需要了")
        }
    }

    private lazy var internalPlugin: SKLoadingPlugin = {
        let plugin = SKLoadingPlugin()
        plugin.logPrefix = model?.jsEngine.editorIdentity ?? ""
        plugin.pluginProtocol = self
        return plugin
    }()
}

extension UtilLoadingService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.utilShowLoading, .utilHideLoading, .utilHideLoadingOverTime]
    }

    private var identifier: String {
        return model?.jsEngine.editorIdentity ?? ""
    }

    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.utilHideLoading.rawValue:
            internalPlugin.handle(params: params, serviceName: serviceName)
        case DocsJSService.utilShowLoading.rawValue:
            showLoading(params: params)
        default:
            spaceAssertionFailure()
        }
    }
    
    func showLoading(params: [String: Any]) {
        
    }
}

extension UtilLoadingService: SKLoadingPluginProtocol {
    func hidLoading(params: [String: Any]) {
        DocsLogger.info("\(identifier) 收到前端 hideLoading 通知", extraInfo: params)
        jsService(self, setLoadingState: .end)
        model?.openRecorder.appendInfo("receive utilHideLoading")
    }
    
    
}
