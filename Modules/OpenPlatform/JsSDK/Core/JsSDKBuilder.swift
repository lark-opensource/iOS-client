//
//  JsSDKBuilder.swift
//  Lark
//
//  Created by K3 on 2018/5/22.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import WebBrowser
import LarkContainer

public typealias JsAPIHandlerDict = [String: () -> LarkWebJSAPIHandler]

public protocol JsAPIHandlerProvider {
    var handlers: JsAPIHandlerDict { get }
}

/// JsAPIHandler 拆分前后对比 https://bytedance.feishu.cn/docs/doccnj9WDuhs2Sf1gwTlARrBKAg
public struct JsSDKBuilder {

    public static func initJsSDK(_ api: WebBrowser, resolver: UserResolver, handlerProviders: [JsAPIHandlerProvider], scope: JsAPIMethodScope = .all) -> LarkWebJSSDK {
        if case .none = scope {
            return JsSDKBuilder.initJsSDK(api, resolver: resolver, handlerDict: [:])
        } else {
            let handlerDict = handlerProviders.reduce([:]) { (result, provider) -> JsAPIHandlerDict in
                let newHandles: JsAPIHandlerDict
                switch scope {
                case .all:
                    newHandles = provider.handlers
                case .allow(let methods):
                    newHandles = provider.handlers.filter({ (handler) -> Bool in
                        methods.contains(handler.key)
                    })
                case .block(let methods):
                    newHandles = provider.handlers.filter({ (handler) -> Bool in
                        !methods.contains(handler.key)
                    })
                case .none:
                    assertionFailure("should not run here")
                    newHandles = [:]
                }
                var hdlrs = result
                hdlrs.merge(newHandles) { (_, new) -> () -> LarkWebJSAPIHandler in
                    new
                }
                return hdlrs
            }
            return JsSDKBuilder.initJsSDK(api, resolver: resolver, handlerDict: handlerDict)
        }
    }

    public static func initJsSDK(_ api: WebBrowser, resolver: UserResolver, handlerDict: JsAPIHandlerDict) -> LarkWebJSSDK {
        let jsSDK = JsSDKImpl(api: api, r: resolver)
        registJSSDK(apiDict: handlerDict, jsSDK: jsSDK)
        return jsSDK
    }

    fileprivate static func wrapAPIGetter(_ getter: @escaping () -> LarkWebJSAPIHandler) -> () -> LarkWebJSAPIHandler {
        var handler: LarkWebJSAPIHandler?
        return {
            if handler != nil {
                return handler!
            }

            handler = getter()
            return handler!
        }
    }

   public static func registJSSDK(apiDict: [String: () -> LarkWebJSAPIHandler], jsSDK: LarkWebJSSDK) {
        apiDict.forEach { (method, creator) in
            let getter = wrapAPIGetter(creator)
            jsSDK.regist(method: method, apiGetter: getter)
        }
    }
}

public extension Array where Element == JsAPIHandlerProvider {
    func handlers() -> JsAPIHandlerDict {
        let handlerDicts: JsAPIHandlerDict = self.reduce([:]) { (result, provider) -> JsAPIHandlerDict in
            var handlers = result
            handlers.merge(provider.handlers) { (_, new) -> () -> LarkWebJSAPIHandler in
                return new
            }
            return handlers
        }
        return handlerDicts
    }
}


public extension JsSDKBuilder {

    static func jsSDKWithAllProvider(api: WebBrowser, resolver: UserResolver, scope: JsAPIMethodScope) -> LarkWebJSSDK {
        JsSDKBuilder.initJsSDK(
            api,
            resolver: resolver,
            handlerProviders: Self.allHandlerProviders(api: api, resolver: resolver),
            scope: scope
        )
    }

    static func allHandlerProviders(api: WebBrowser, resolver: UserResolver) -> [JsAPIHandlerProvider] {
        return [
            BaseJsAPIHandlerProvider(api: api, resolver: resolver),
            CommonJsAPIHandlerProvider(api: api, resolver: resolver),
            BizJsAPIHandlerProvider(resolver: resolver),
            DeviceJsAPIHandlerProvider(),
            DynamicJsAPIHandlerProvider(api: api, resolver: resolver),
            PassportJsAPIHandlerProvider(resolver: resolver)
        ]
    }
}
