//
//  CommentOpenPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2021/7/6.
//  


import LarkOpenPluginManager
import LarkOpenAPIModel
import SKFoundation
import SpaceInterface
import LarkContainer

public final class CommentOpenPlugin: OpenBasePlugin {

    var commentPlugin: CommentPlugin?
    
    var pluginHandler: CommentOpenPluginHandler?
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        commentPlugin = CommentPlugin()
        registerAllService()
        registerEvent(event: "enviromentDidLoad", paramsType: OpenAPIEnviromentDidLoadParams.self) { [weak self] (param, context, callback )in
            let data = param.data // 携带数据
            self?.pluginHandler?.update(context: context)
            DocsLogger.info("comment enviromentDidLoad", component: LogComponents.gadgetComment)
            callback(.success(data: nil))
        }
        
        registerEvent(event: "enviromentTerminate", paramsType: OpenAPIWorkerEnviromentParams.self) { [weak self] _, _, callback in
            DocsLogger.info("enviromentTerminate", component: LogComponents.gadgetComment)
            callback(.success(data: nil))
            self?.pluginHandler?.enviromentTerminate()
            self?.commentPlugin = nil
        }
        
        registerEvent(event: "onAppSessionChanged", paramsType: OpenAPIWorkerEnviromentParams.self) { [weak self] param, _, callback in
            let session = param.data["session"]
            DocsLogger.info("onAppSessionChanged", component: LogComponents.gadgetComment)
            self?.pluginHandler?.updateSession(session)
            callback(.success(data: nil))
        }
    }
    
    public override class func supportEvents() -> [Any] {
        return ["enviromentDidLoad", "enviromentTerminate", "onAppSessionChanged"]
    }
}



extension CommentOpenPlugin {
    
    func registerAllService() {
        
        guard let jsServiceManager = self.commentPlugin?.jsServiceManager else {
            return
        }
        pluginHandler = CommentOpenPluginHandler(delegate: jsServiceManager)
        for jsBridge in pluginHandler!.allServices {
            DocsLogger.info("registerAsyncHandler \(jsBridge)", component: LogComponents.gadgetComment)
            registerAsyncHandler(for: jsBridge,
                                 paramsType: OpenAPICommentParams.self,
                                 resultType: DocsOpenAPIResult.self) { [weak self] (params, context, callback) in
                guard let self = self else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                            .setMonitorMessage("self is nil When call API")
                    callback(.failure(error: error))
                    return
                }
                guard let data = params.data as? [String: Any] else { return }
                DocsLogger.info("receive handler message \(jsBridge)", component: LogComponents.gadgetComment)
                let gadgetCallback = GadgetCommentCallback { res in
                    switch res {
                    case let .success(params):
                        callback(.success(data: .init(params: params)))
                    case let .failure(error):
                        let apiError = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                                .setMonitorMessage("\(error)")
                        callback(.failure(error: apiError))
                    }
                }
                self.pluginHandler?.handle(context: context, message: jsBridge, data, callback: gadgetCallback)
            }
        }
    }
}
