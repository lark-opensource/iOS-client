//
//  TranslatedByReceiverCompententViewModel.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/2/17.
//

import Foundation
import EENavigator
import LarkMessageBase
import LarkMessengerInterface

final class TranslatedByReceiverCompententViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: NewMessageSubViewModel<M, D, C> {
    /// 消息被其他人自动翻译icon点击事件
    func autoTranslateTapHandler() {
        guard let controller = context.pageAPI else {
            assertionFailure()
            return
        }
        let effectBody = TranslateEffectBody(
            chat: metaModel.getChat(),
            message: message
        )
        self.context.navigator.push(body: effectBody, from: controller)
    }
}
