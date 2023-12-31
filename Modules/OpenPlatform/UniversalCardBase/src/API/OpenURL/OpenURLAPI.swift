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
open class UniversalCardOpenURLAPI: UniversalCardAPIPlugin {
    
    enum APIName: String {
        case UniversalCardOpenUrl
    }
    
    private func openURL(
        params: UniversalCardOpenURLRequest,
        context: UniversalCardAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            guard let actionService = context.cardContext.dependency?.actionService,
                let sourceVC = context.cardContext.sourceVC else {
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                context.apiTrace.error("sendRequest API: action service or sourceVC is nil")
                return
            }

            let actionContext = UniversalCardActionContext(
                trace: context.cardContext.renderingTrace?.subTrace() ?? context.cardContext.trace.subTrace(),
                elementTag: nil,
                elementID: params.elementID,
                bizContext: context.cardContext.bizContext,
                actionFrom: .innerLink()
            )
            actionService.openUrl(
                context: actionContext,
                cardID: context.cardContext.sourceData?.cardID,
                urlStr: params.url,
                from: sourceVC
            ) { error in
                if (error == nil) {
                    context.apiTrace.error("sendRequest API: request success")
                    callback(.success(data: OpenAPIUniversalCardResult(.success, resultCode: .success)))
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
            for: APIName.UniversalCardOpenUrl.rawValue,
            pluginType: Self.self,
            paramsType: UniversalCardOpenURLRequest.self,
            resultType: OpenAPIBaseResult.self
        ) { (this, params, context, callback) in
            this.openURL(params: params, context: context, callback: callback)
        }
    }
}
