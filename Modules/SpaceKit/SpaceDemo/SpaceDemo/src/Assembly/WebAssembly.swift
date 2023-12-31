//
//  WebAssembly.swift
//  SpaceDemo
//
//  Created by 曾浩泓 on 2022/5/27.
//  Copyright © 2022 Bytedance. All rights reserved.

import Foundation
import Swinject
import BootManager
import LarkWebViewContainer
import LarkOPInterface
import LKTracing
import LKLoadable
import LarkAssembler

class WebAssembly: LarkAssemblyInterface {
    public init() {}
    
    public func registContainer(container: Swinject.Container) {
        container.register(LarkWebViewProtocol.self) { _ in
            LarkWebViewProtocolImpl()
        }.inObjectScope(.user)
        container.register(LarkWebViewQualityServiceProtocol.self) { _ in
            QualityService()
        }
    }
    public func registLaunch(container: Container) {
        NewBootManager.register(SetupOPInterfaceTask.self)
    }
}
class LarkWebViewProtocolImpl: LarkWebViewProtocol {
    public func setupAjaxFetchHook(webView: LarkWebView) {}
    public func ajaxFetchHookString() -> String? { nil }
}

class SetupOPInterfaceTask: FlowBootTask, Identifiable {
    static var identify = "SetupOPInterfaceTask"

    override func execute(_ context: BootContext) {
        /// OPTrace 全局初始化
        let config = OPTraceConfig(prefix: LKTracing.identifier) { (parent) -> String in
            return LKTracing.newSpan(traceId: parent)
        }
        OPTraceService.default().setup(config)
    }
}
