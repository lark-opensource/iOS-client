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
import UniversalCardInterface
import LarkContainer
// MARK: -
open class UniversalCardSendRequestAPI: UniversalCardAPIPlugin {
    
    enum APIName: String {
        case UniversalCardSendRequest
    }
    
    private func sendRequest(
        params: UniversalCardSendRequestRequest,
        context: UniversalCardAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            guard let actionService = context.cardContext.dependency?.actionService,
                  let sourceData = context.cardContext.sourceData else {
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

            let actionContext = UniversalCardActionContext(
                trace: context.cardContext.renderingTrace?.subTrace() ?? context.cardContext.trace.subTrace(),
                elementTag: params.tag,
                elementID: params.elementID,
                bizContext: context.cardContext.bizContext,
                actionFrom: nil
            )

            // 发送请求
            actionService.sendRequest(
                context: actionContext,
                cardSource: UniversalCardDataActionSourceInfo.from(sourceData),
                actionID: params.actionID,
                params: bizParams
            ) { error, resultType in
                if let resultType = resultType, error == nil  {
                    context.apiTrace.error("sendRequest API: request success")
                    callback(.success(data: UniversalCardSendRequestResponse(result: resultType)))
                } else {
                    context.apiTrace.error("sendRequest API: request fail \(error?.localizedDescription ?? "")")
                    let error = OpenAPIError(errno: OpenAPIMsgCardErrno.requestActionFail)
                    callback(.failure(error: error))
                }
            }
    }
    
    required public init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerCardAsyncHandler(
            for: APIName.UniversalCardSendRequest.rawValue,
            pluginType: Self.self,
            paramsType: UniversalCardSendRequestRequest.self,
            resultType: OpenAPIBaseResult.self
        ) { (this, params, context, callback) in
            this.sendRequest(params: params, context: context, callback: callback)
        }
    }

}
