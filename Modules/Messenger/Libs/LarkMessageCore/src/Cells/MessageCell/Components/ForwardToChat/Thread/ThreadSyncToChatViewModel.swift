//
//  ThreadSyncToChatViewModel.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/8/23.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import RichLabel
import EENavigator
import LarkCore
import LarkUIKit
import LarkMessengerInterface
import EEAtomic
import LarkAlertController
import LarkSDKInterface
import LarkContainer
import RxSwift

public protocol ThreadSyncToChatComponentViewModelContext: PageContext { }

public class ThreadSyncToChatComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ThreadSyncToChatComponentViewModelContext>: MessageSubViewModel<M, D, C> {
    public var textFont: UIFont { UIFont.ud.caption0 }
    public var iconSize: CGSize { CGSize(width: UIFont.ud.caption2.rowHeight,
                                         height: UIFont.ud.caption2.rowHeight) }
    let disposeBag = DisposeBag()

    public var text: String {
        let chat = metaModel.getChat()
        if chat.type == .p2P {
            return BundleI18n.LarkMessageCore.Lark_IM_AlsoSentChat_Thread_Text
        } else {
            return BundleI18n.LarkMessageCore.Lark_IM_AlsoSentGroup_Thread_Text
        }
    }

    public func syncToChatDidTapped() {
        let chat = metaModel.getChat()
        // 若syncToChatRelatedMessage或syncToChatRelatedMessageID存在，则跳转到会话内的关联消息并高亮
        // 假消息syncToChatRelatedMessageID为空不做跳转
        if let position = metaModel.message.syncToChatRelatedMessage?.position {
            let body = ChatControllerByIdBody(chatId: chat.id,
                                              position: position)
            context.navigator(type: .push, body: body, params: nil)
        // 若syncToChatRelatedMessage为nil，会重新从SDK获取关联消息跳转
        } else if !metaModel.message.syncToChatRelatedMessageID.isEmpty {
            let id = metaModel.message.syncToChatRelatedMessageID
            let messageAPI = try? context.userResolver.resolve(assert: MessageAPI.self)
            messageAPI?.fetchMessage(id: id).subscribe(onNext: { [weak self] message in
                guard let self = self else { return }
                let position = message.position
                let body = ChatControllerByIdBody(chatId: chat.id, position: position)
                self.context.navigator(type: .push, body: body, params: nil)
            }).disposed(by: disposeBag)
        }
    }
}
