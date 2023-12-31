//
//  EventShareComponentFactory.swift
//  Calendar
//
//  Created by zoujiayi on 2019/6/26.
//

import UIKit
import LarkModel
import LarkMessageBase
import AsyncComponent
import UniverseDesignColor

extension PageContext: EventShareViewModelContext {
    var scene: LarkMessageBase.ContextScene {
        return self.dataSourceAPI?.scene ?? .newChat
    }

    func getEventShareBinder(model: EventShareModelImpl) -> EventShareBinder? {
        let calendarInterface = try? userResolver.resolve(assert: CalendarInterface.self)
        return calendarInterface?.getCalendarEventShareBinder(controllerGetter: { [weak self] () in
            return self?.pageAPI ?? UIViewController()
        }, model: model)
    }
}

class EventShareComponentFactory<C: EventShareViewModelContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is EventShareContent
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return EventShareViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: LarkEventShareBinder<M, D, C>(context: context),
            propsPatch: { [weak self] (props, message) in
                guard let self = self else { return props }
                let props = props
                if self.needBottomPadding(message: message) {
                    props.needBottomPadding = false
                }
                return props
            }
        )
    }

    // 会话页面，话题样式下不需要BottomPadding
    func needBottomPadding(message: Message) -> Bool {
        return message.showInThreadModeStyle
    }
}

final class MergeForwardEventShareComponentFactory<C: EventShareViewModelContext>: EventShareComponentFactory<C> {
    override func needBottomPadding(message: Message) -> Bool {
        return false
    }
}

final class ChatPinEventShareComponentFactory<C: EventShareViewModelContext>: EventShareComponentFactory<C> {
    override func needBottomPadding(message: Message) -> Bool {
        return true
    }
}

final class ThreadEventShareComponentFactory<C: EventShareViewModelContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is EventShareContent
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        let binder = LarkEventShareBinder<M, D, C>(
            context: context,
            borderGetter: {
                return Border(BorderEdge(width: 1, color: EventCardStyle.borderColor, style: .solid))
            }, cornerRadiusGetter: {
                return 10
            }
        )

        return EventShareViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: binder,
            propsPatch: { (props, _) in
                let props = props
                // 小组/话题内的日程分享卡片不需要BottomPadding
                props.needBottomPadding = false
                return props
            }
        )
    }
}

final class DetailEventShareComponentFactory<C: EventShareViewModelContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is EventShareContent
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        let binder = LarkEventShareBinder<M, D, C>(
            context: context,
            borderGetter: {
                return Border(BorderEdge(width: 1, color: EventCardStyle.borderColor, style: .solid))
            }, cornerRadiusGetter: {
                return 10
            }
        )

        return EventShareViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: binder,
            propsPatch: { (props, _) in
                let props = props
                // IM 消息树内的日程分享卡片不需要BottomPadding
                props.needBottomPadding = false
                return props
            }
        )
    }
}
