//
//  QuickActionListComponentFactory.swift
//  LarkAI
//
//  Created by Hayden on 22/8/2023.
//

import Foundation
import LarkContainer
import LarkRustClient
import LarkMessageBase
import LarkSDKInterface
import LarkMessengerInterface

protocol QuickActionFactoryContext: QuickActionBinderContext {}

final class QuickActionComponentFactory<C: QuickActionFactoryContext>: MessageSubFactory<C> {

    override class var subType: SubType {
        return .quickActions
    }

    override var canCreateBinder: Bool {
        return true
    }

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        // 必须是和MyAI的主分会场才展示
        guard metaModel.getChat().isP2PAi else { return false }
        // MyAI回复的才展示
        guard metaModel.message.fromChatter?.type == .ai else { return false }
        // 撤回的消息不展示
        guard !metaModel.message.isRecalled else { return false }
        return true
    }

    override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return QuickActionComponentBinder(
            viewModel: QuickActionComponentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            actionHandler: QuickActionComponentActionHandler(context: context)
        )
    }
}

extension PageContext: QuickActionFactoryContext {
    var myAIService: LarkMessengerInterface.MyAIService? {
        return try? userResolver.resolve(type: MyAIService.self)
    }

    var quickActionSendService: MyAIQuickActionSendService? {
        return try? userResolver.resolve(type: MyAIQuickActionSendService.self)
    }

    var pushCenter: PushNotificationCenter? {
        return try? userResolver.userPushCenter
    }

    var rustSDKService: SDKRustService? {
        return try? userResolver.resolve(type: SDKRustService.self)
    }
}
