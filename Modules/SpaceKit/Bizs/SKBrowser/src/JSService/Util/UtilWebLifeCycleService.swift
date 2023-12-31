//
//  UtilWebLifeCycleService.swift
//  SpaceKit
//
//  Created by Webster on 2019/9/20.
//

import Foundation
import SKCommon
import SKInfra

public final class UtilWebLifeCycleService: BaseJSService {
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension UtilWebLifeCycleService: BrowserViewLifeCycleEvent {
    public func browserWillClear() {
        GeckoPackageManager.shared.syncResourcesIfNeeded()
    }
}

extension UtilWebLifeCycleService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return []
    }

    public func handle(params: [String: Any], serviceName: String) {

    }
}
