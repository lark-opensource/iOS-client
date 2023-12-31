//
//  ThreadCellViewModelFactory.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/1/29.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import LarkCore
import LarkContainer
import EEFlexiable
import LarkMessageCore
import LarkMessageBase
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkKAFeatureSwitch
import LarkAppConfig
import LarkFeatureGating
import LarkSearchCore

struct ThreadCellMetaModelDependency: CellMetaModelDependency {
    let contentPadding: CGFloat
    let contentPreferMaxWidth: (Message) -> CGFloat
    let config: ThreadCellConfig
    init(
        contentPadding: CGFloat,
        contentPreferMaxWidth: @escaping (Message) -> CGFloat,
        config: ThreadCellConfig = .default
    ) {
        self.contentPadding = contentPadding
        self.contentPreferMaxWidth = contentPreferMaxWidth
        self.config = config
    }

    func getContentPreferMaxWidth(_ message: Message) -> CGFloat {
        return self.contentPreferMaxWidth(message)
    }
}

struct ThreadCellConfig {
    public static let `default` = ThreadCellConfig()
}

final class ThreadCellViewModelFactory: CellViewModelFactory<ThreadMessageMetaModel, ThreadCellMetaModelDependency, ThreadContext> {
    /// 新话题线
    func createSign() -> ThreadCellViewModel {
        return ThreadSignCellViewModel(context: context)
    }

    /// 历史消息线
    func createHistorySign() -> ThreadCellViewModel {
        return ThreadHistoryCellViewModel(context: context)
    }

    func createTopMsgTip(tip: String) -> ThreadCellViewModel {
        return ThreadTopMsgTipCellViewModel(tip: tip, context: context)
    }

    func createPreviewTip(copyWriting: String) -> ThreadCellViewModel {
        return ThreadPreviewTipCellViewModel(copyWriting: copyWriting, context: context)
    }

    override func createMessageCellViewModel(
        with model: ThreadMessageMetaModel,
        metaModelDependency: ThreadCellMetaModelDependency,
        contentFactory: ThreadMessageSubFactory,
        subFactories: [SubType: ThreadMessageSubFactory]
    ) -> ThreadCellViewModel {
        return ThreadMessageCellViewModel(
            metaModel: model,
            metaModelDependency: metaModelDependency,
            context: context,
            contentFactory: contentFactory,
            getContentFactory: self.getContentFactory,
            subFactories: subFactories,
            cellLifeCycleObseverRegister: self.cellLifeCycleObseverRegister
        )
    }

    override func createSystemCellViewModel(with model: ThreadMessageMetaModel, metaModelDependency: ThreadCellMetaModelDependency) -> ThreadCellViewModel {
        return ThreadSystemCellViewModel(metaModel: model, context: context)
    }

    override func registerServices() {
        context.pageContainer.register(ColorConfigService.self) {
            return ThreadColorConfig()
        }
    }
}

final class ThreadChatTextPostContentFactory: TextPostContentFactory<ThreadContext> {

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> ThreadMessageSubViewModel<M, D> {
        var config = TextPostConfig()
        let titleFont = UIFont.ud.title3
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = titleFont.rowHeight
        paragraphStyle.maximumLineHeight = titleFont.rowHeight
        paragraphStyle.lineBreakMode = .byTruncatingTail
        config.titleRichAttributes = [
            .foregroundColor: UIColor.ud.N900,
            .font: titleFont,
            .paragraphStyle: paragraphStyle
        ]

        config.contentLineSpacing = 4
        /// thread 默认不展开内容
        config.isAutoExpand = false
        config.translateIsAutoExpand = config.isAutoExpand

        let binder = TextPostContentComponentBinder<M, D, ThreadContext>(context: context)
        binder.component._style.width = 100%

        return ThreadTextPostContentViewModel(
            content: metaModel.message.content,
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: binder,
            config: config
        )
    }

}
