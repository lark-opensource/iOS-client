//
//  BTStatisticOpenFileJSService.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/12/1.
//

import Foundation
import SKBrowser
import SKCommon
import SKFoundation
import SKInfra

final class BTBaseReportService: BaseJSService {
    private let helper: BTBaseReportServiceHelper

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        helper = BTBaseReportServiceHelper()
        super.init(ui: ui, model: model, navigator: navigator)
        helper.setupRouter(delegate: self)
    }
}

extension BTBaseReportService: BTStatisticReportHandleDelegate {
    var traceId: String? {
        return browserVC?.fileConfig?.getOpenFileTraceId()
    }

    private var browserVC: BrowserViewController? {
        guard let vc = self.registeredVC as? BrowserViewController else {
            DocsLogger.btError("[BTBaseReportService] registeredVC is not BrowserViewController")
            return nil
        }
        return vc
    }

    var isBitable: Bool {
        return model?.hostBrowserInfo.docsInfo?.inherentType == .bitable
    }

    var token: String? {
        return model?.hostBrowserInfo.docsInfo?.token
    }

    var baseToken: String? {
        return model?.hostBrowserInfo.docsInfo?.objToken
    }

    var objTokenInLog: String? {
        return model?.hostBrowserInfo.docsInfo?.objTokenInLog
    }

    func addObserver(_ o: BrowserViewLifeCycleEvent) {
        model?.browserViewLifeCycleEvent.addObserver(o)
    }
}

extension BTBaseReportService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.baseReport]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard UserScopeNoChangeFG.LYL.enableStatisticTrace else {
            return
        }
        guard model?.hostBrowserInfo.openSessionID != nil else {
            DocsLogger.btError("BTBaseReportService get openSessionID fail")
            return
        }
        helper.handle(params: params, serviceName: serviceName)
    }
}
