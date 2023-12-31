//
//  SelectMessagesHandler.swift
//  microapp-iOS-sdk
//
//  Created by Zigeng on 2022/8/21.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import LKCommonsLogging
import EENavigator
import WebBrowser
import LarkMessengerInterface
import UniverseDesignToast
import LarkContainer

// 消息选择器JSB
class SelectMessagesHandler: JsAPIHandler {
    static let logger = Logger.log(SelectMessagesHandler.self, category: "Module.JSSDK")
    
    private let resolver: UserResolver
    
    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let chatId = args["chatId"] as? String, !chatId.isEmpty else {
            SelectMessagesHandler.logger.error("Wrong parameters")
            return
        }

        var body = MessagePickerBody(chatId: chatId, needDocAuth: false)
        body.cancel = { [weak api] disappearReason in
            switch disappearReason {
            case .viewWillDisappear:
                callback.callbackSuccess(param: [
                    "cancel": true,
                    "msgIds": []
                ])
            case .cancelBtnClick:
                api?.navigationController?.popViewController(animated: true)
            }
        }

        body.finish = { [weak callback, weak api] (messages, _) in
            guard let callback = callback else {
                return
            }
            var messageIds = messages.map { $0.id }
            guard let api = api else { return }
            if messageIds.isEmpty {
                guard let window = api.navigationController?.topViewController?.view  else {
                    return
                }
                // 提示用户在消息选择器中至少选择一条消息
                let errorMessage = BundleI18n.JsSDK.Lark_IM_Report_SelectChatHistoryAndTryAgain_Toast
                if Thread.isMainThread {
                    UDToast.showFailure(with: errorMessage, on: window )
                } else {
                    DispatchQueue.main.async {
                        UDToast.showFailure(with: errorMessage, on: window )
                    }
                }
            } else {
                callback.callbackSuccess(param: [
                    "cancel": false,
                    "msgIds": messageIds
                ])
                api.navigationController?.popViewController(animated: true)
            }
        }
        resolver.navigator.push(body: body, from: api)
    }
}
