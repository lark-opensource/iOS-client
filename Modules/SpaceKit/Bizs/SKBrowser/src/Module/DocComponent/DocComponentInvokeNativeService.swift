//
//  DocComponentInvokeNativeService.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/5/25.
//  


import SKFoundation
import SKCommon
import LarkWebViewContainer
import SpaceInterface

public final class DocComponentInvokeNativeService: BaseJSService {

}

extension DocComponentInvokeNativeService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.invokeNativeForDC]
    }
    
    public func handle(params: [String: Any], serviceName: String) {
        spaceAssertionFailure()
    }
    
    public func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        guard let docComponentDelegate = self.model?.docComponentDelegate else {
            spaceAssertionFailure("must in docComponent")
            return
        }
        docComponentDelegate.docComponentHost(self.docComponentHost,
                                              onReceiveWebInvoke: params,
                                              callback: callback)
    }
}
