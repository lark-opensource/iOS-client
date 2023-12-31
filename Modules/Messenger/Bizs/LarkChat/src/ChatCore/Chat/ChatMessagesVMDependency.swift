//
//  ChatMessagesVMDependency.swift
//  Lark
//
//  Created by zc09v on 2018/4/4.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import LarkModel
import LarkUIKit
import LarkContainer
import LarkCore
import Swinject
import LKCommonsLogging
import LarkMessageCore
import LarkSDKInterface
import LarkMessengerInterface
import SuiteAppConfig

final class ChatMessagesVMDependency: UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy var messageAPI: MessageAPI?
    @ScopedInjectedLazy var threadAPI: ThreadAPI?
    @ScopedInjectedLazy var myAIAPI: MyAIAPI?
    @ScopedInjectedLazy var userUniversalSettingService: UserUniversalSettingService?

    let channelId: String
    let currentChatterID: String
    let audioShowTextEnable: Bool
    let chatKeyPointTracker: ChatKeyPointTracker
    let readService: ChatMessageReadService
    // 密聊不支持URL预览
    let urlPreviewService: MessageURLPreviewService?
    let processMessageSelectedEnable: (Message) -> Bool
    /// 密聊会用到这个功能
    let getFeatureIntroductions: () -> [String]

    init(
        userResolver: UserResolver,
        channelId: String,
        currentChatterID: String,
        audioShowTextEnable: Bool,
        chatKeyPointTracker: ChatKeyPointTracker,
        readService: ChatMessageReadService,
        urlPreviewService: MessageURLPreviewService?,
        processMessageSelectedEnable: @escaping (Message) -> Bool,
        getFeatureIntroductions: @escaping () -> [String]
    ) {
        self.userResolver = userResolver
        self.channelId = channelId
        self.currentChatterID = currentChatterID
        self.audioShowTextEnable = audioShowTextEnable
        self.chatKeyPointTracker = chatKeyPointTracker
        self.processMessageSelectedEnable = processMessageSelectedEnable
        self.readService = readService
        self.urlPreviewService = urlPreviewService
        self.getFeatureIntroductions = getFeatureIntroductions
    }
}
