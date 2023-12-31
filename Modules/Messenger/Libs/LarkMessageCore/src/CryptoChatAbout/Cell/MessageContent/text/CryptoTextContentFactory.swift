//
//  CryptoTextPostContentFactory.swift
//  LarkMessageCore
//
//  Created by zc09v on 2021/9/13.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import EENavigator
import LarkSetting
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer
import LarkInteraction
import LarkZoomable
import RichLabel
import LarkCore
import LKCommonsLogging

open class CryptoTextContentFactory<C: PageContext>: MessageSubFactory<C> {
    private var logger = Logger.log(CryptoTextContentFactory.self, category: "LarkMessage.CryptoTextContentFactory")
    open override class var subType: SubType {
        return .content
    }

    open override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is TextContent
    }

    open override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        var config = TextPostConfig()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 24
        paragraphStyle.maximumLineHeight = UIFont.ud.title3.rowHeight
        paragraphStyle.lineBreakMode = .byTruncatingTail
        config.titleRichAttributes = [
            .foregroundColor: UIColor.ud.N900,
            .font: UIFont.ud.title3,
            .paragraphStyle: paragraphStyle
        ]

        config.contentLineSpacing = 2
        config.attacmentImageCornerRadius = 0
        config.attacmentImageborderWidth = 0
        config.attacmentImageborderColor = UIColor.clear

        // code_next_line tag CryptChat
        /// chat 根据type区分是否展开
        config.isAutoExpand = false
        config.translateIsAutoExpand = config.isAutoExpand
        config.needPostViewTapHandler = false
        return CryptoChatTextContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: CryptoTextContentComponentBinder(context: context),
            config: config
        )
    }

    open override func registerDragHandler<M: CellMetaModel, D: CellMetaModelDependency>(with dargManager: DragInteractionManager, metaModel: M, metaModelDependency: D) {
        let handler = MessageContentDragHandler(modelService: self.context.modelService)
        let translateHandler = MessageTranslateDragHandler(modelService: self.context.modelService)
        dargManager.register(handler)
        dargManager.register(translateHandler)
    }
}
