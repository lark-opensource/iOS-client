//
//  UtilImpactFeedback.swift
//  SpaceKit
//
//  Created by huahuahu on 2019/1/28.
//

import Foundation
import WebKit
import SKCommon

public final class UtilImpactFeedbackService: BaseJSService {
    private lazy var internalPlugin: SKBaseImpactFeedbackPlugin = {
        let plugin = SKBaseImpactFeedbackPlugin()
        plugin.logPrefix = model?.jsEngine.editorIdentity ?? ""
        return plugin
    }()
}

extension UtilImpactFeedbackService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return internalPlugin.handleServices
    }

    public func handle(params: [String: Any], serviceName: String) {
        internalPlugin.handle(params: params, serviceName: serviceName)
    }
}
