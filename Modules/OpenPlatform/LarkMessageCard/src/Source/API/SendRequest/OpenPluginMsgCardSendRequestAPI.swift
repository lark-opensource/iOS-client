//
//  OpenPluginSendRequestAPI.swift
//  LarkMessageCard
//
//  Created by ByteDance on 2023/4/27.
//

import Foundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import LarkAlertController
import Lynx
import EENavigator
import LarkNavigator
import LarkContainer

// MARK: -
open class OpenPluginMsgCardSendRequestAPI: OpenBasePlugin {
    
    enum APIName: String {
        case msgCardSendRequest
    }
    
    private func sendRequest(
        params: OpenPluginMsgCardSendRequestRequest,
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
            // Rust 只接受 string: string 类型数据
            guard let bizParams = params.params as? [String: String] else {
                let error = OpenAPIError(errno: OpenAPICommonErrno.invalidParam(.paramWrongType(param: "\(String(describing: params.params.self))")))
                callback(.failure(error: error))
                context.apiTrace.error("sendRequest API: request with wrong param type: \(String(describing: params.params.self))")
                return
            }
            let actionContext = MessageCardActionContext(
                elementTag: params.tag,
                elementID: params.elementID,
                bizContext: msgContext.bizContext,
                actionFrom: nil
            )
            let lynxView = MsgCardAPIUtils.getLynxView(context: context)
            // 发送请求
            actionService.sendAction(
                context: actionContext,
                actionID: params.actionID,
                params: bizParams,
                isMultiAction: false,
                updateActionState: nil) { error, resultType in
                    if let resultType = resultType, error == nil {
                        context.apiTrace.error("sendRequest API: request success")
                        callback(.success(data: MessageCardSendRequestResponse(result: resultType.rawValue)))
                    } else {
                        context.apiTrace.error("sendRequest API: request fail \(error?.localizedDescription ?? "")")
                        let error = OpenAPIError(errno: OpenAPIMsgCardErrno.requestActionFail)
                        callback(.failure(error: error))
                    }
                }
    }
    
    required public init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(
            for: APIName.msgCardSendRequest.rawValue,
            pluginType: Self.self,
            paramsType: OpenPluginMsgCardSendRequestRequest.self,
            resultType: OpenAPIBaseResult.self
        ) { (this, params, context, callback) in
            this.sendRequest(params: params, context: context, callback: callback)
        }
    }
}
