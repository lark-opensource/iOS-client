//
//  ToConversationHandler.swift
//  Lark
//
//  Created by ChalrieSu on 2018/4/12.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//
import LKCommonsLogging
import EENavigator
import WebBrowser
import LarkMessengerInterface
import LarkContainer

class ToConversationHandler: JsAPIHandler {
    static let logger = Logger.log(ToConversationHandler.self, category: "Module.JSSDK")

    private let resolver: UserResolver
    
    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let chatId = args["chatId"] as? String else {
            ToConversationHandler.logger.error("参数有误")
            return
        }
        let body = ChatControllerByIdBody(chatId: chatId, fromWhere: .profile)
        resolver.navigator.push(body: body, from: api) { (_, res) in
            if res.error == nil {
                callback.callbackSuccess(param: ["code": 0])
            } else {
                callback.callbackSuccess(param: ["code": 1])
            }
        }
    }
}
