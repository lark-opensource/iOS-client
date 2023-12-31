//
//  ActionButtonComponentViewModel.swift
//  LarkAI
//
//  Created by 李勇 on 2023/5/16.
//

import Foundation
import LarkModel
import LarkCore
import LarkMessageBase
import LarkAIInfra
import LarkMessengerInterface
import ThreadSafeDataStructure

public protocol ActionButtonViewModelContext: ViewModelContext {
    var myAIPageService: MyAIPageService? { get }
}

public class ActionButtonComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ActionButtonViewModelContext>: NewMessageSubViewModel<M, D, C> {
    private var didTrackerOutputShow: Bool = false

    /// ActionButton
    public var actionButtons: ThreadSafeDataStructure.SafeArray<MyAIChatModeConfig.ActionButton> {
        guard let myAIPageService = self.context.myAIPageService else { return [] + .readWriteLock }
        return myAIPageService.chatModeConfig.actionButtons + .readWriteLock
    }

    public override func willDisplay() {
        super.willDisplay()
        guard !self.didTrackerOutputShow, let myAIPageService = self.context.myAIPageService else { return }
        self.didTrackerOutputShow = true

        IMTracker.Msg.OutputShow(
            self.metaModel.getChat(),
            self.metaModel.message,
            params: myAIPageService.chatMode ? ["app_name": myAIPageService.chatModeConfig.extra["app_name"] ?? "other"] : [:],
            myAIPageService.chatFromWhere
        )
    }

    public override func shouldUpdate(_ new: Message) -> Bool {
        return false
    }
}
