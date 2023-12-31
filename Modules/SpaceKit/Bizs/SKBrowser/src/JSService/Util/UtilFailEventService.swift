//
//  UtilFailEventService.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/9/11.
//

import Foundation
import WebKit
import SKCommon
import SKFoundation

class UtilFailEventService: BaseJSService {
    var jsEngine: BrowserJSEngine? { model?.jsEngine }
    var loadingReporter: BrowserLoadingReporter? { model?.loadingReporter }
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension UtilFailEventService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.utilFailEvent]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard let errCode = params["result_code"] as? Int else {
            DocsLogger.error("open doc fail with params", extraInfo: ["params": params, "browserView": "\(self.editorIdentity)"], error: nil, component: LogComponents.fileOpen)
            spaceAssertionFailure()
            return
        }

        let errorData = params["data"] as? [String: Any]
        DocsLogger.error("open doc fail \(self.editorIdentity)", extraInfo: ["errCode": errCode, "errData": "\(String(describing: errorData?.description))"], error: nil, component: LogComponents.fileOpen)

        let loadStatus = self.model?.browserInfo.loadStatus ?? .unknown
        if loadStatus.canContinue == false {
            //当加载状态已经是超时或失败，不再继续响应新的failEvent
            DocsLogger.error("ignore new fail/oops event(code:\(errCode)) when loadStatus:\(String(describing: loadStatus))", component: LogComponents.fileOpen)
            return
        }
        
        // 展示给用户
        let error = NSError(domain: LoaderErrorDomain.failEventFromH5, code: errCode, userInfo: nil)
        loadingReporter?.failWithError(error)
    }
}
