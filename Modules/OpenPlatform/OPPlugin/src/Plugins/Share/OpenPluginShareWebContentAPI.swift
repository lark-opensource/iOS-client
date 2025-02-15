//
//  OpenPluginShareWebContentAPI.swift
//  LarkOpenApis
//
//  GENERATED BY ANYCODE on 2022/8/30 09:37:28
//  DO NOT MODIFY!!!
//

import Foundation
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LarkOpenPluginManager
import LarkContainer
import LarkOPInterface
import EENavigator

class OpenPluginShareWebContentAPI: OpenBasePlugin {
    
    enum APIName: String {
        case shareWebContent
    }
    
    public func shareWebContent(
        params: OpenPluginShareWebContentRequest,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginShareWebContentResponse>) -> Void) {
            guard let gadgetContext = context.gadgetContext, let controller = gadgetContext.controller else {
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage("gadgetContext nil? \(context.gadgetContext == nil)")
                callback(.failure(error: error))
                return
            }
            let urlStr: String = params.url
            guard let url = URL(string: urlStr) else {
                let error = OpenAPIError(errno: OpenAPICommonErrno.invalidParam(.invalidParam(param: "url")))
                    .setMonitorMessage("url invalid patam: \(params.url)")
                callback(.failure(error: error))
                return
            }
            let title: String? = params.title
            let shareH5Content = ShareH5Content(title: title, link: urlStr)
            let shareBody = OPShareBody(shareType: .h5(shareH5Content), fromType: .shareH5API)
            userResolver.navigator.open(body: shareBody, from: controller)
            callback(.success(data: nil))
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: APIName.shareWebContent.rawValue, pluginType: Self.self, paramsType: OpenPluginShareWebContentRequest.self, resultType: OpenPluginShareWebContentResponse.self) { (this, params, context, gadgetContext, callback) in
            context.apiTrace.info("shareWebContent API call start")
            this.shareWebContent(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
            context.apiTrace.info("shareWebContent API call end")
        }
    }
}
