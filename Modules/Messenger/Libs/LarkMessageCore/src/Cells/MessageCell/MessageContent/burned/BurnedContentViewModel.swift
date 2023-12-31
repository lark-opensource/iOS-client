//
//  BurnedContentViewModel.swift
//  Action
//
//  Created by 赵冬 on 2019/8/10.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import RichLabel
import LarkCore
import EENavigator

public final class BurnedContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: BurnedContentContext>: MessageSubViewModel<M, D, C> {
    override public var identifier: String {
        return "burned"
    }

    /// 显示内容
    private(set) var string = String()
    /// 字体
    var labelFont: UIFont {
        return self.context.scene == .newChat ? UIFont.ud.title4 : UIFont.ud.body0
    }

    public init(metaModel: M, metaModelDependency: D, context: C) {
        super.init(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: BurnedContentComponentBinder<M, D, C>(context: context)
        )
    }

    public override func initialize() {
        parseMessage(self.message)
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        parseMessage(metaModel.message)
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }

    private func parseMessage(_ message: Message) {
        self.generateLabelText(with: message.recaller)
    }

    private func generateLabelText(with recaller: Chatter?) {
        self.string = message.isOnTimeDel ? BundleI18n.LarkMessageCore.Lark_IM_MsgDeleted_Desc : BundleI18n.LarkMessageCore.Lark_Legacy_MessageBurned
    }
}
