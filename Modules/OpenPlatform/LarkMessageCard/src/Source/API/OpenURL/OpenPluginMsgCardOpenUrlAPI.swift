//
//  OpenPluginMsgCardOpenUrlAPI.swift
//  LarkMessageCard
//
//  Created by zhangjie.alonso on 2023/10/27.
//

import Foundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import LarkAlertController
import Lynx
import EENavigator
import LarkNavigator
import UniversalCardInterface
import LarkContainer


open class OpenPluginMsgCardOpenUrlAPI: OpenBasePlugin {

    enum APIName: String {
        case msgCardOpenUrl
    }

    private func openURL(
        params: OpenPluginMsgCardOpenUrlRequest,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            guard let msgContext = context.additionalInfo["msgContext"] as? MessageCardLynxContext,
                  let bizContext = msgContext.bizContext as? MessageCardContainer.Context,
                  let actionService = bizContext.dependency?.actionService else {
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                context.apiTrace.error("sendRequest API: action service is nil")
                return
            }
            let actionContext = MessageCardActionContext(
                elementTag: params.tag,
                elementID: params.elementID,
                bizContext: msgContext.bizContext,
                actionFrom: .innerLink()
            )
            actionService.openUrl(context: actionContext, urlStr: params.url)
            callback(.success(data: nil))
    }

    required public init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(
            for: APIName.msgCardOpenUrl.rawValue,
            pluginType: Self.self,
            paramsType: OpenPluginMsgCardOpenUrlRequest.self,
            resultType: OpenAPIBaseResult.self
        ) { (this, params, context, callback) in
            this.openURL(params: params, context: context, callback: callback)
        }
    }
}
