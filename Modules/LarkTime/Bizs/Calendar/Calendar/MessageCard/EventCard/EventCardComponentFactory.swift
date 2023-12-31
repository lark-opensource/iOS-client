//
//  EventCardComponentFactory.swift
//  LarkCalendar
//
//  Created by heng zhu on 2019/6/17.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import AsyncComponent
import LarkFeatureGating
import UniverseDesignColor

enum EventCardStyle {
    static let borderColor = UDColor.current.getValueByBizToken(token: "imtoken-message-card-border") ?? UIColor.ud.lineBorderCard
}

extension PageContext: LarkEventCardViewModelContext {
    func getCalendarEventCardBinder(model: CardDataModelImp) -> EventCardBinder? {
        let calendarInterface = try? userResolver.resolve(assert: CalendarInterface.self)

        return calendarInterface?.getCalendarEventCardBinder(controllerGetter: { [weak self] () in
            return self?.pageAPI ?? UIViewController()
        }, model: model)
    }

}

extension CalendarBotContent {
    func isKnownMessage() -> Bool {
        guard let messageType = self.messageType else {
            return false
        }

        return CardType.allCases
            .filter { $0 != .unknown }
            .map { $0.rawValue }
            .contains(messageType)
    }
}

class EventCardComponentFactory<C: LarkEventCardViewModelContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        if let content = metaModel.message.content as? CalendarBotContent {
            return content.isKnownMessage()
        }
        return false
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return LarkEventCardViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: LarkEventCardBinder<M, D, C>(context: context),
            propsPatch: { [weak self] (props, message) in
                guard let self = self else { return props }
                let props = props
                if self.needBottomPadding(message: message) {
                    props.needBottomPadding = false
                }
                props.needHorizontalPadding = self.needHorizontalPadding(message: message)
                return props
            }
        )
    }

    // 会话页面，话题样式下不需要BottomPadding
    func needBottomPadding(message: Message) -> Bool {
        return message.showInThreadModeStyle
    }

    // 是否需要减去左右padding，话题转发卡片场景需要左右间距，maxWidth需要减左右间距
    func needHorizontalPadding(message: Message) -> Bool {
        return false
    }
}

class MessageLinkEventCardComponentFactory<C: LarkEventCardViewModelContext>: EventCardComponentFactory<C> {
    override func needHorizontalPadding(message: Message) -> Bool {
        return true
    }
}

class ChatPinEventCardComponentFactory<C: LarkEventCardViewModelContext>: EventCardComponentFactory<C> {
    override func needHorizontalPadding(message: Message) -> Bool {
        return true
    }

    override func needBottomPadding(message: Message) -> Bool {
        return true
    }
}

final class MergeForwardEventCardComponentFactory<C: LarkEventCardViewModelContext>: EventCardComponentFactory<C> {
    override func needBottomPadding(message: Message) -> Bool {
        return false
    }
}

final class ThreadEventCardComponentFactory<C: LarkEventCardViewModelContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        if let content = metaModel.message.content as? CalendarBotContent {
            return content.isKnownMessage()
        }
        return false
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        let binder = LarkEventCardBinder<M, D, C>(context: context, borderGetter: {
            return Border(BorderEdge(width: 1, color: EventCardStyle.borderColor, style: .solid))
        })

        return LarkEventCardViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: binder,
            propsPatch: { (props, _) in
                let props = props
                // Thread中一直需要bottom padding
                props.needBottomPadding = false
                return props
            }
        )
    }
}

final class DetailEventCardComponentFactory<C: LarkEventCardViewModelContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        if let content = metaModel.message.content as? CalendarBotContent {
            return content.isKnownMessage()
        }
        return false
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        let binder = LarkEventCardBinder<M, D, C>(context: context, borderGetter: {
            return Border(BorderEdge(width: 1, color: EventCardStyle.borderColor, style: .solid))
        })

        let model = LarkEventCardViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: binder
        )
        return model
    }
}
