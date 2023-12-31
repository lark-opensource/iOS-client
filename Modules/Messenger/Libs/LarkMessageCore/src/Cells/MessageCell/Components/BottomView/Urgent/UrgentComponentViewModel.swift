//
//  UrgentComponentViewModel.swift
//  LarkMessageCore
//
//  Created by 赵冬 on 2020/4/7.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import RichLabel
import EENavigator
import LarkUIKit
import LarkCore
import LarkMessengerInterface

public protocol UrgentComponentViewModelContext: ViewModelContext {
    func isBurned(message: Message) -> Bool
    @available(*, deprecated, message: "this function could't judge anonymous scene, the best is to use new isMe with metaModel parameter")
    func isMe(_ chatterId: String) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool
}

/// 管理左上角加急icon和长按菜单中加急item的显示
final class UrgentComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: UrgentComponentViewModelContext>: MessageSubViewModel<M, D, C> {
    public override init(metaModel: M, metaModelDependency: D, context: C, binder: ComponentBinder<C>) {
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

    public var iconSize = CGSize(width: 27, height: 27)
}
