//
//  LarkEventCardViewModel.swift
//  LarkCalendar
//
//  Created by heng zhu on 2019/6/17.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import RxSwift
import RustPB
import LarkContainer
import LarkAccountInterface

protocol LarkEventCardViewModelContext: ViewModelContext {
    func getCalendarEventCardBinder(model: CardDataModelImp) -> EventCardBinder?
    var scene: LarkMessageBase.ContextScene { get }
    var userResolver: UserResolver { get }
}

final class LarkEventCardViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: LarkEventCardViewModelContext>: MessageSubViewModel<M, D, C> {
    var eventCardComponentProps: EventCardComponentProps {
        let cardDataModel = CardDataModelImp(content: self.content, message: message, chatId: metaModel.getChat().id, tenantId: tenantId)
        self.calendarBinder?.updateModel(cardDataModel)
        var props = calendarBinder?.componentProps ?? EventCardComponentProps()
        if let propsPatch = propsPatch {
            props = propsPatch(props, self.message)
        }
        let padding: CGFloat = props.needHorizontalPadding ? 12 * 2 : 0
        props.maxWidth = self.contentWidth - padding
        return props
    }

    private var tenantId: String {
        if let userService = try? context.userResolver.resolve(assert: PassportUserService.self) {
            return userService.userTenant.tenantID
        }
        return ""
    }

    private var propsPatch: ((_ props: EventCardComponentProps, _ message: Message) -> EventCardComponentProps)?

    private lazy var calendarBinder: EventCardBinder? = {
        let cardDataModel = CardDataModelImp(content: self.content, message: message, chatId: metaModel.getChat().id, tenantId: tenantId)
        return context.getCalendarEventCardBinder(model: cardDataModel)
    }()

    private var disposeBag = DisposeBag()
    private var hasTracedView = false
    public override var identifier: String {
        return "calendarEvent"
    }

    required init(metaModel: M, metaModelDependency: D, context: C, binder: ComponentBinder<C>, propsPatch: ((_ props: EventCardComponentProps, _ message: Message) -> EventCardComponentProps)? = nil) {
        self.propsPatch = propsPatch
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    public override var contentConfig: ContentConfig? {
        var config = ContentConfig(hasMargin: false, backgroundStyle: .white, maskToBounds: true, supportMutiSelect: true, hasBorder: true)
        config.isCard = true
        return config
    }

    public var messageId: String {
        return message.id
    }
    public var content: CalendarBotContent {
        return (message.content as? CalendarBotContent)!
    }

    var contentWidth: CGFloat {
        return min(metaModelDependency.getContentPreferMaxWidth(message), 370)
    }

    public override func willDisplay() {
        super.willDisplay()
        self.disposeBag = DisposeBag()
        calendarBinder?.maxWidth = contentWidth
        calendarBinder?.reloadViewPublish.subscribe(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.binder.update(with: self)
            self.update(component: self.binder.component)
        }).disposed(by: disposeBag)
        if !hasTracedView {
            CalendarTracerV2.EventCard.traceView {
                $0.is_invited = (self.calendarBinder?.componentProps.rsvpStatus != .removed).description
                $0.is_updated = self.calendarBinder?.componentProps.isInvalid.description ?? ""
                $0.chat_id = self.metaModel.getChat().id
                $0.event_type = self.content.isWebinar ? "webinar" : "normal"
                $0.is_new_card_type = "false"
                $0.is_support_reaction = "false"
                $0.is_bot = "true"
                $0.is_share = "false"
                $0.is_reply_card = (self.calendarBinder?.componentProps.rsvpStatus != .removed).description
                $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: self.content.eventId,
                                                                       eventStartTime: self.content.startTime?.description,
                                                                       isRecurrence: !self.content.rrepeat.isEmpty,
                                                                       originalTime: self.content.originalTime?.description,
                                                                       uid: self.content.key))
            }
            hasTracedView = true
        }
    }

    public override func didEndDisplay() {
        super.didEndDisplay()
        self.disposeBag = DisposeBag()
    }

}
