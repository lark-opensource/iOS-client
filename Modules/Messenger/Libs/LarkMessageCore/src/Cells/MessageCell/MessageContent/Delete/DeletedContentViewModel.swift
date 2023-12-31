//
//  DeleteContentViewModel.swift
//  Action
//
//  Created by 赵冬 on 2019/8/3.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import RichLabel
import LarkCore
import EENavigator

public final class DeletedContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: DeletedContentContext>: MessageSubViewModel<M, D, C> {
    override public var identifier: String {
        return "deleted"
    }

    /// 显示内容
    private(set) var string = String()
    /// 字体
    private(set) var labelFont: UIFont = UIFont.ud.body0

    public init(metaModel: M, metaModelDependency: D, context: C) {
        super.init(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: DeletedContentComponentBinder<M, D, C>(context: context)
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
        self.string = BundleI18n.LarkMessageCore.Lark_Legacy_MessageAlreadyDeleted
    }

}
