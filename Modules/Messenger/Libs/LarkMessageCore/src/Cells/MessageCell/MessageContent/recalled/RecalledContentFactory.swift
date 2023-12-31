//
//  RecalledContentFactory.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/3/1.
//

import UIKit
import Foundation
import LarkModel
import AsyncComponent
import LarkMessageBase
import LarkSetting

public protocol RecalledContentContext: ViewModelContext, ColorConfigContext {
    var isNewRecallEnable: Bool { get }
    var scene: ContextScene { get }
    func reedit(_ message: Message)
    @available(*, deprecated, message: "this function could't judge anonymous scene, the best is to use new isMe with metaModel parameter")
    func isMe(_ chatterID: String) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool

    func canCreateSystemRecalledCell(_ message: Message) -> Bool
}

public class RecalledContentFactory<C: RecalledContentContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override var priority: Bool {
        return true
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.isRecalled
    }

    public override var canCreateBinder: Bool {
        true
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(
        with metaModel: M,
        metaModelDependency: D
    ) -> NewComponentBinder<M, D, C> {
        return RecalledContentComponentBinder(
            context: self.context,
            viewModel: RecalledContentViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: self.context,
                config: getRecallContentConfig()
            ),
            actionHandler: RecalledMessageActionHandler(context: self.context)
        )
    }

    public func getRecallContentConfig() -> RecallContentConfig {
        var recallConfig = RecallContentConfig()
        recallConfig.isShowReedit = true
        return recallConfig
    }
}

public final class ChatRecalledContentFactory<C: RecalledContentContext>: RecalledContentFactory<C> {
    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        if context.canCreateSystemRecalledCell(metaModel.message) {
            return false
        }
        return super.canCreate(with: metaModel)
    }
}

public final class MessageDetailRecalledContentFactory<C: RecalledContentContext>: RecalledContentFactory<C> {
    public override func getRecallContentConfig() -> RecallContentConfig {
        var recallConfig = RecallContentConfig()
        recallConfig.isShowReedit = false
        return recallConfig
    }
}

public final class MessageLinkRecalledContentFactory<C: RecalledContentContext>: RecalledContentFactory<C> {
    public override func getRecallContentConfig() -> RecallContentConfig {
        var recallConfig = RecallContentConfig()
        recallConfig.isShowReedit = false
        recallConfig.showRecaller = false
        return recallConfig
    }
}

extension PageContext: RecalledContentContext {
    public func reedit(_ message: Message) {
        self.pageAPI?.reedit(message)
    }

    public var isNewRecallEnable: Bool {
        return self.getStaticFeatureGating(FeatureGatingManager.Key(stringLiteral: "im.messenger.new_recall"))
    }

    public func canCreateSystemRecalledCell(_ message: Message) -> Bool {
        /// Thread in Chat模式在撤回时不需要直接转换成为系统消息
        return isNewRecallEnable && message.isRecalled && !message.showInThreadModeStyle
    }
}
