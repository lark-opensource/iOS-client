//
//  ActionButtonComponentActionHandler.swift
//  LarkAI
//
//  Created by 李勇 on 2023/5/16.
//

import UIKit
import LarkModel
import LarkCore
import Foundation
import LarkAIInfra
import LarkMessageBase
import LarkMessengerInterface

public protocol ActionButtonActionHanderContext: ViewModelContext {
    var myAIPageService: MyAIPageService? { get }
}

class ActionButtonComponentActionHandler<C: ActionButtonActionHanderContext>: ComponentActionHandler<C> {
    public func actionButtonClick(button: MyAIChatModeConfig.ActionButton, chat: Chat, message: Message) {
        guard let myAIPageService = self.context.myAIPageService else { return }

        IMTracker.Msg.Menu.Click.Output(
            chat,
            message,
            params: myAIPageService.chatMode ? ["app_name": myAIPageService.chatModeConfig.extra["app_name"] ?? "other"] : [:],
            myAIPageService.chatFromWhere
        )

        MyAIPageServiceImpl.logger.info("my ai tap action button, key: \(button.key)")
        let actionData = MyAIChatModeConfig.ActionButtonData(type: .markdown, content: message.aiAnswerRawData)
        button.callback(actionData)
    }
}
