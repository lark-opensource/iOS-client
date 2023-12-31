//
//  VChatMeetingCardFactory.swift
//  Action
//
//  Created by Prontera on 2019/6/4.
//

import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import ByteViewInterface
import LarkSDKInterface
import LarkFeatureGating
import ByteViewCommon
import LarkAccountInterface
import ByteViewNetwork
import ByteViewSetting
import AsyncComponent

protocol VChatMeetingCardContext: ComponentContext & VChatMeetingCardViewModelContext {}

class VChatMeetingCardFactory<C: VChatMeetingCardContext>: MessageSubFactory<C> {

    override required init(context: C) {
        super.init(context: context)
        self.loadGenericTypes()
    }

    override class var subType: SubType {
        return .content
    }

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is VChatMeetingCardContent
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return VChatMeetingCardViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: VChatMeetingCardComponentBinder<M, D, C>(context: context)
        )
    }

    private func loadGenericTypes() {
        // 初始化泛型缓存，防止崩溃
        let testObj: Any = NSObject()
        _ = testObj as? VChatMeetingCardContent
        _ = testObj as? VChatMeetingCardContent.MeetingCard
        _ = testObj as? VChatMeetingCardContent.ParticipantType
    }
}

class ThreadVChatMeetingCardFactory<C: VChatMeetingCardContext>: MessageSubFactory<C> {
    override class var subType: SubType {
        return .content
    }

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is VChatMeetingCardContent
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M,
                                                                       metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return VChatMeetingCardViewModel(metaModel: metaModel,
                                         metaModelDependency: metaModelDependency,
                                         context: context,
                                         binder: VChatMeetingCardComponentBinder<M, D, C>(context: context))
    }
}

class DetailVChatMeetingCardFactory<C: VChatMeetingCardContext>: MessageSubFactory<C> {
    override class var subType: SubType {
        return .content
    }

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is VChatMeetingCardContent
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M,
                                                                       metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return VChatMeetingCardViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: VChatMeetingCardWithBorderComponentBinder<M, D, C>(context: context)
        )
    }
}

extension PageContext: VChatMeetingCardContext {
    var scene: ContextScene {
        return dataSourceAPI?.scene ?? .newChat
    }
}
