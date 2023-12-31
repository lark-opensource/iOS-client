//
//  CryptoCountDownStatusViewModel.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2023/2/17.
//

import Foundation
import LarkModel
import AsyncComponent
import EEFlexiable
import RxSwift
import Swinject
import LarkMessageBase
import LarkMessengerInterface

public final class CryptoCountDownStatusViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: CountDownViewModelContext>: CountDownStatusViewModel<M, D, C> {
    /// 暂时不进行倒计时。当 自己是发送方 && 还有人未读
    override var pauseBurnWhenAnyOneUnReadForSender: Bool {
        return context.isMe(message.fromId, chat: metaModel.getChat())
            && message.unreadCount != 0
    }
}
