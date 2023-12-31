//
//  MessageDetailMessagesVMDependency.swift
//  Action
//
//  Created by 赵冬 on 2019/7/24.
//

import Foundation
import RxCocoa
import RxSwift
import LarkModel
import LarkUIKit
import LarkMessengerInterface
import LarkContainer
import LarkCore
import Swinject
import LKCommonsLogging
import LarkMessageCore
import LarkRustClient
import LarkSDKInterface

final class MessageDetailMessagesVMDependency {
    // log
    let currentChatterId: String
    let channelId: String
    let chatWrapper: ChatPushWrapper
    let messageAPI: MessageAPI
    let rustService: RustService
    let pushDynamicNetStatusObservable: Observable<PushDynamicNetStatus>
    let pushChannelMessages: Observable<PushChannelMessages>
    let chatMessageReadService: ChatMessageReadService
    let messageBurnService: MessageBurnService
    let urlPreviewService: MessageURLPreviewService?
    let pushHandlerRegister: MessageDetailPushHandlersRegister

    init(
        channelId: String,
        chatWrapper: ChatPushWrapper,
        currentChatterId: String,
        messageAPI: MessageAPI,
        rustService: RustService,
        pushCenter: PushNotificationCenter,
        chatMessageReadService: ChatMessageReadService,
        messageBurnService: MessageBurnService,
        urlPreviewService: MessageURLPreviewService?,
        pushHandlerRegister: MessageDetailPushHandlersRegister) {

        self.channelId = channelId
        self.chatWrapper = chatWrapper
        self.currentChatterId = currentChatterId
        self.messageAPI = messageAPI
        self.rustService = rustService
        self.pushDynamicNetStatusObservable = pushCenter.observable(for: PushDynamicNetStatus.self)
        self.pushChannelMessages = pushCenter.observable(for: PushChannelMessages.self)
        self.chatMessageReadService = chatMessageReadService
        self.messageBurnService = messageBurnService
        self.urlPreviewService = urlPreviewService
        self.pushHandlerRegister = pushHandlerRegister
    }
}
