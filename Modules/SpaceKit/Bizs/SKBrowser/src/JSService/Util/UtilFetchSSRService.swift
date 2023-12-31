//
//  UtilFetchSSRService.swift
//  SKBrowser
//
//  Created by huangzhikai on 2023/9/7.
//

import Foundation
import SKCommon
import SpaceInterface
import UniverseDesignToast
import SKFoundation
import LarkWebViewContainer
public final class UtilFetchSSRService: BaseJSService {
    
    //并发队列
    lazy var taskQueue = DispatchQueue(label: "UtilFetchSSRService-HtmlCache", attributes: .concurrent)
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension UtilFetchSSRService: DocsJSServiceHandler {

    
    public var handleServices: [DocsJSService] {
        return [.utilFetchSSR]
    }
    
    public func handle(params: [String : Any], serviceName: String) { }
    
    public func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        DocsLogger.info("UtilFetchSSRService, serviceName=\(serviceName) \(self.editorIdentity)", component: LogComponents.fetchSSR)
        let token = params["token"] as? String
        let type = params["type"] as? Int
        guard let token = token, !token.isEmpty else {
            DocsLogger.error("UtilFetchSSRService，token is nil", component: LogComponents.fetchSSR)
            callbackJS(callback: callback, code: -1)
            return
        }
        guard let type = type else {
            DocsLogger.error("UtilFetchSSRService，type is nil", component: LogComponents.fetchSSR)
            callbackJS(callback: callback, code: -1)
            return
        }
        
        let docsType = DocsType(rawValue: type)
        guard docsType == .docX else {
            DocsLogger.error("UtilFetchSSRService，error type:\(docsType), is no docx, ", component: LogComponents.fetchSSR)
            callbackJS(callback: callback, code: -1)
            return
        }
        
        guard token.isFakeToken == false else {
            DocsLogger.info("UtilFetchSSRService，token is FakeToken \(token.encryptToken)", component: LogComponents.fetchSSR)
            callbackJS(callback: callback, code: -1)
            return
        }
        
        var htmlTask = NativePerloadHtmlTask(key: PreloadKey(objToken: token, type: DocsType(rawValue: type)), taskQueue: self.taskQueue)
        DocsLogger.info("UtilFetchSSRService，start fecth ssr，token：\(token.encryptToken)，type：\(type)", component: LogComponents.fetchSSR)
        htmlTask.finishTask = { [weak self] loadErr in
            DocsLogger.info("UtilFetchSSRService, fecth finish code: \(loadErr)，token：\(token.encryptToken)，type：\(type)", component: LogComponents.fetchSSR)
            guard let self = self else {
                DocsLogger.info("UtilFetchSSRService，self is nil，token：\(token.encryptToken)，type：\(type)", component: LogComponents.fetchSSR)
                return
            }
            self.callbackJS(callback: callback, code: loadErr)
        }
        //手动发起ssr请求
        //忽略ssr缓存发起请求，前端发起的证明这里是一定要下载新的ssr，为了复用预加载拉ssr的代码流程，就加了个忽略缓存的方法，走重新拉ssr并缓存本地的流程
        htmlTask.startForceRequest { _ in }
    }
    
    private func callbackJS(callback: APICallbackProtocol?, code: Int) {
        guard let callback = callback else {
            DocsLogger.info("UtilFetchSSRService，fecth end and callback is nil, resultCode:\(code)", component: LogComponents.fetchSSR)
            return
        }
        DocsLogger.info("UtilFetchSSRService，fecth end and callback, resultCode: \(code) ", component: LogComponents.fetchSSR)
        callback.callbackSuccess(param: ["code": code])
    }
}
