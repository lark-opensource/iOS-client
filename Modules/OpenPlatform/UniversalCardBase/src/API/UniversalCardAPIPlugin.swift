//
//  UniversalCardAPI.swift
//  UniversalCardBase
//
//  Created by ByteDance on 2023/8/26.
//

import Foundation
import EENavigator
import LarkOpenAPIModel
import UniversalCardInterface
import LarkOpenPluginManager
open class UniversalCardAPIPlugin: OpenBasePlugin {
    public typealias AsyncHandlerInstance<PluginType: OpenBasePlugin, Param: OpenAPIBaseParams, Result: OpenAPIBaseResult> = (
        _ this: PluginType,
        _ params: Param,
        _ context: UniversalCardAPIContext,
        _ callback: @escaping (OpenAPIBaseResponse<Result>) -> Void
    ) throws -> Void


    public func registerCardAsyncHandler<PluginType, Param, Result>(
        for apiName: String,
        pluginType: PluginType.Type = PluginType.self,
        paramsType: Param.Type = Param.self,
        resultType: Result.Type = Result.self,
        handler: @escaping AsyncHandlerInstance<PluginType, Param, Result>
    ) where PluginType: OpenBasePlugin, Param: OpenAPIBaseParams, Result: OpenAPIBaseResult {
        super.registerInstanceAsyncHandler(
            for: apiName,
            pluginType: pluginType,
            paramsType: paramsType,
            resultType: resultType
        ) { (this, params, context, callback) in
            guard let context = context as? UniversalCardAPIContext else {
                return
            }
            try handler(this, params, context, callback)
        }
    }

    public func presentController(vc: UIViewController, context: UniversalCardAPIContext) {
        if let fromVC = context.cardContext.sourceVC {
            userResolver.navigator.present(vc, wrap: nil, from: fromVC, prepare: { controller in
                #if canImport(CryptoKit)
                if #available(iOS 13.0, *) {
                    if controller.modalPresentationStyle == .automatic {
                        controller.modalPresentationStyle = .fullScreen
                    }
                }
                #endif
            })
        } else {
            context.apiTrace.error("presentController fail, fromVC is nil")
        }
    }
    
    static let PopoverDefaultEdges = UIEdgeInsets(edges: -4)
}
