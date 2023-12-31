//
//  ThreadDetailRecallActionSubModule.swift
//  LarkThread
//
//  Created by Zigeng on 2023/3/22.
//

import Foundation
import LarkModel
import RxSwift
import LarkOpenChat
import LarkContainer
import LarkMessageBase
import LarkAlertController
import LarkSDKInterface
import LarkCore
import LKCommonsLogging
import LarkAccountInterface
import LarkMessageCore

public class ThreadDetailRecallMessageActionSubModule: RecallMessageActionSubModule {
    @ScopedInjectedLazy private var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy var threadAdminService: ThreadAdminService?
    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        let chat = model.chat
        let currentChatterId = context.userID
        let isMessageSender = (currentChatterId == model.message.fromId)
        // 这里取isTopicGroupAdmin 来判断是否可以撤回
        let isAdmin = threadAdminService?.getCurrentAdminInfo()?.isTopicGroupAdmin ?? false

        if !isAdmin,
           !model.chat.isGroupAdmin,
           !(tenantUniversalSettingService?.getIfMessageCanRecallBySelf() ?? false) {
            return false
        }

        let notRootMessage = !model.message.rootId.isEmpty
        let canRecall = isMessageSender || (currentChatterId == chat.ownerId) || isAdmin || model.chat.isGroupAdmin
        return notRootMessage && canRecall
    }
}
