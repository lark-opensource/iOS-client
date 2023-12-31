//
//  MessageCardContainerDependencyImpl.swift
//  LarkOpenPlatform
//
//  Created by ByteDance on 2022/12/12.
//

import Foundation
import LarkModel
import ECOProbe
import LarkMessageBase
import LarkMessageCard


class MessageCardContaienrDependencyImpl: MessageCardContainerDependency {
    var actionService: LarkMessageCard.MessageCardActionService?
    weak var sourceVC: UIViewController?

    init(
        message: LarkModel.Message,
        trace: OPTrace,
        pageContext: PageContext,
        chat: @escaping () -> LarkModel.Chat,
        actionEventHandler: MessageCardActionEventHandler
    ) {
        actionService = MessageCardActionServiceImpl(
            message: message,
            trace: trace,
            pageContext: pageContext,
            chat: chat,
            handler: actionEventHandler
        )
        sourceVC = pageContext.pageAPI
    }
    
    func update(message: LarkModel.Message) {
        guard let actionService = actionService as? MessageCardActionServiceImpl else {
            return
        }
        actionService.update(message: message)
    }
}
