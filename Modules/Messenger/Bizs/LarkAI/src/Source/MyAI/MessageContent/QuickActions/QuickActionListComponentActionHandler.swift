//
//  QuickActionListComponentActionHandler.swift
//  LarkAI
//
//  Created by Hayden on 22/8/2023.
//

import UIKit
import Foundation
import RustPB
import ServerPB
import RxSwift
import LarkCore
import LarkModel
import LarkContainer
import LarkRustClient
import AsyncComponent
import LarkMessageBase
import LarkSDKInterface
import UniverseDesignToast
import LarkMessengerInterface
import LarkAIInfra

protocol QuickActionActionHanderContext: ViewModelContext {
    var myAIPageService: MyAIPageService? { get }
    var quickActionSendService: MyAIQuickActionSendService? { get }
}

class QuickActionComponentActionHandler<C: QuickActionActionHanderContext>: ComponentActionHandler<C> {

    private let disposeBag = DisposeBag()

    /// 发起重新生成请求
    func handleQuickActionClick(_ quickAction: AIQuickActionModel, chat: Chat, message: Message) {
        guard let quickActionSendService = context.quickActionSendService else { return }
        // 调用 QuickActionSendService，执行快捷指令
        if let sdkQuickAction = quickAction as? Im_V1_QuickAction {
            reportQuickActionClickEvent(sdkQuickAction, chat: chat, message: message)
            quickActionSendService.handleAIQuickAction(sdkQuickAction, sendTracker: QuickActionSendTracker(sendCallback: { [weak self] isEdited, _ in
                self?.reportQuickActionSendEvent(sdkQuickAction, isEdited: isEdited, chat: chat, message: message)
            }))
        } else if let serverQuickAction = quickAction as? ServerPB_Office_ai_QuickAction {
            reportQuickActionClickEvent(serverQuickAction, chat: chat, message: message)
            quickActionSendService.handleAIQuickAction(serverQuickAction, sendTracker: QuickActionSendTracker(sendCallback: { [weak self] isEdited, _ in
                self?.reportQuickActionSendEvent(serverQuickAction, isEdited: isEdited, chat: chat, message: message)
            }))
        }
    }

    /// 上报快捷指令点击埋点
    private func reportQuickActionClickEvent(_ quickAction: AIQuickActionModel, chat: Chat, message: Message) {
        guard let pageService = context.myAIPageService as? MyAIPageServiceImpl else { return }
        pageService.quickActionTracker.reportQuickActionClickEvent(
            quickAction,
            roundId: String(pageService.aiRoundInfo.value.roundId),
            location: .followMessage,
            fromChat: chat,
            extraParams: ["message_id": "\(message.id)", "session_id": pageService.aiRoundInfo.value.sessionID ?? ""]
        )
    }

    /// 上报快捷指令发送埋点
    private func reportQuickActionSendEvent(_ quickAction: AIQuickActionModel, isEdited: Bool, chat: Chat, message: Message) {
        guard let pageService = context.myAIPageService as? MyAIPageServiceImpl else { return }
        pageService.quickActionTracker.reportQuickActionSendEvent(
            quickAction,
            roundId: String(pageService.aiRoundInfo.value.roundId),
            location: .followMessage,
            isEdited: isEdited,
            fromChat: chat,
            extraParams: ["message_id": "\(message.id)", "session_id": pageService.aiRoundInfo.value.sessionID ?? ""]
        )
    }
}
