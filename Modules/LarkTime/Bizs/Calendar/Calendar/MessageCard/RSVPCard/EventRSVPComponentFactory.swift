//
//  EventRSVPComponentFactory.swift
//  Calendar
//
//  Created by pluto on 2023/1/18.
//

import UIKit
import LarkModel
import LarkMessageBase
import AsyncComponent
import UniverseDesignColor

extension PageContext: EventRSVPViewModelContext {

    func getEventRSVPBinder(model: EventRSVPModelImpl) -> EventRSVPBinder? {
        let calendarInterface = try? userResolver.resolve(assert: CalendarInterface.self)
        return calendarInterface?.getCalendarEventRSVPCardBinder(controllerGetter: { [weak self] () in
            return self?.pageAPI ?? UIViewController()
        }, model: model)
    }
}


class EventRSVPComponentFactory<C: EventRSVPViewModelContext>: MessageSubFactory<C> {
    override class var subType: SubType {
        return .content
    }

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is GeneralCalendarEventRSVPContent
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return EventRSVPViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: LarkEventRSVPBinder<M, D, C>(context: context),
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

final class MergeForwardEventRSVPComponentFactory<C: EventRSVPViewModelContext>: EventRSVPComponentFactory<C> {
    override func needBottomPadding(message: Message) -> Bool {
        return false
    }
}

final class ChatPinEventRSVPComponentFactory<C: EventRSVPViewModelContext>: EventRSVPComponentFactory<C> {
    override func needBottomPadding(message: Message) -> Bool {
        return true
    }
}

final class ThreadEventRSVPComponentFactory<C: EventRSVPViewModelContext>: MessageSubFactory<C> {
    override class var subType: SubType {
        return .content
    }

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is GeneralCalendarEventRSVPContent
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        let binder = LarkEventRSVPBinder<M, D, C>(
            context: context,
            borderGetter: {
                return Border(BorderEdge(width: 1, color: EventCardStyle.borderColor, style: .solid))
            }, cornerRadiusGetter: {
                return 10
            }
        )

        return EventRSVPViewModel(
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

final class DetailEventRSVPComponentFactory<C: EventRSVPViewModelContext>: MessageSubFactory<C> {
    override class var subType: SubType {
        return .content
    }

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is GeneralCalendarEventRSVPContent
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        let binder = LarkEventRSVPBinder<M, D, C>(
            context: context,
            borderGetter: {
                return Border(BorderEdge(width: 1, color: EventCardStyle.borderColor, style: .solid))
            }, cornerRadiusGetter: {
                return 10
            }
        )

        return EventRSVPViewModel(
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

